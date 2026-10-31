"""Entrenamiento, evaluación y comparación de los modelos de UnderLaw.

Uso (desde mineria/):
    venv\\Scripts\\python -m underlaw_ml.entrenar            # fuente según .env (auto)
    venv\\Scripts\\python -m underlaw_ml.entrenar mysql      # exige MySQL
    venv\\Scripts\\python -m underlaw_ml.entrenar csv        # usa data/export

Problemas (ver docs/definicion_problema.md):
  P1 Regresión  · unidades por semana (base: regresión lineal; avanzados: Random Forest, Gradient Boosting)
  P2 Clasificación · recompra en 60 días (base: regresión logística; avanzados: Random Forest, MLP)
  P3 Clustering · segmentos de clientes (K-means vs mezcla gaussiana vs jerárquico)

Todas las métricas que se reportan salen de esta ejecución; nada se escribe a mano.
"""
import json
import sys
import time
from datetime import datetime, timedelta

import joblib
import numpy as np
import pandas as pd
from sklearn.cluster import AgglomerativeClustering, KMeans
from sklearn.compose import ColumnTransformer
from sklearn.decomposition import PCA
from sklearn.ensemble import GradientBoostingRegressor, RandomForestClassifier, RandomForestRegressor
from sklearn.inspection import permutation_importance
from sklearn.linear_model import LinearRegression, LogisticRegression
from sklearn.metrics import (accuracy_score, calinski_harabasz_score, confusion_matrix, davies_bouldin_score,
                             f1_score, mean_absolute_error, mean_squared_error, precision_score, r2_score,
                             recall_score, roc_auc_score, roc_curve, silhouette_score)
from sklearn.mixture import GaussianMixture
from sklearn.model_selection import StratifiedKFold, TimeSeriesSplit, cross_val_score
from sklearn.neural_network import MLPClassifier
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import FunctionTransformer, OneHotEncoder, StandardScaler

from . import caracteristicas as C
from .config import DIR_DOCS, DIR_EXPORT, DIR_MODELOS, FECHA_CORTE, SEMILLA
from .datos import cargar, items_aprobados

SEMANAS_PRUEBA = 16
CORTE_PRUEBA_P2 = pd.Timestamp("2026-02-01")


def _r(x, n=4):
    return None if x is None else round(float(x), n)


def metricas_regresion(y, p) -> dict:
    y, p = np.asarray(y, float), np.asarray(p, float)
    positivos = y > 0
    return {
        "MAE": _r(mean_absolute_error(y, p), 3),
        "RMSE": _r(np.sqrt(mean_squared_error(y, p)), 3),
        "MAPE_%": _r(np.mean(np.abs((y[positivos] - p[positivos]) / y[positivos])) * 100, 2),
        "R2": _r(r2_score(y, p), 4),
    }


def fechas_drops(tablas) -> tuple[list, list]:
    """Fechas locales (Colombia) de los drops: (ya lanzados, programados)."""
    lz = tablas["lanzamientos"].copy()
    lz["fecha_local"] = (lz["fecha_lanzamiento"] - pd.Timedelta(hours=5)).dt.date
    return (lz.loc[lz["estado"] == "lanzado", "fecha_local"].tolist(),
            lz.loc[lz["estado"] == "programado", "fecha_local"].tolist())


# ───────────────────────────── P1 · demanda ─────────────────────────────
def modelos_p1():
    # Los tres predicen el cambio relativo frente al nivel reciente (ver
    # C.ModeloRelativo): así los árboles no quedan limitados por la tendencia.
    return {
        "Regresión lineal": C.ModeloRelativo(Pipeline([("escala", StandardScaler()), ("modelo", LinearRegression())])),
        "Random Forest": C.ModeloRelativo(RandomForestRegressor(n_estimators=300, min_samples_leaf=2,
                                                                random_state=SEMILLA, n_jobs=-1)),
        "Gradient Boosting": C.ModeloRelativo(GradientBoostingRegressor(n_estimators=300, max_depth=2, learning_rate=0.05,
                                                                        subsample=0.9, random_state=SEMILLA)),
    }


def mapa_calor(items: pd.DataFrame, alcance: str, semanas: int = 26) -> dict:
    datos = items if alcance == "todas" else items[items["seccion"] == alcance]
    fin = pd.Timestamp(FECHA_CORTE)
    inicio = pd.Timestamp(C.lunes(FECHA_CORTE)) - pd.Timedelta(weeks=semanas)
    d = datos[(datos["fecha_compra"] >= inicio) & (datos["fecha_compra"] <= fin + pd.Timedelta(days=1))]
    sem = d["fecha_compra"].dt.date.map(C.lunes)
    tabla = d.groupby([sem, d["fecha_compra"].dt.day_of_week])["cantidad"].sum().unstack(fill_value=0)
    lunes = [C.lunes(inicio) + timedelta(weeks=i) for i in range(semanas + 1)]
    tabla = tabla.reindex(index=lunes, columns=range(7), fill_value=0)
    return {"semanas": [l.isoformat() for l in lunes], "dias": ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"],
            "valores": tabla.to_numpy().astype(int).tolist()}


def entrenar_p1(items, drops_pasados, drops_futuros):
    resultado, metricas = {}, {}
    drops_todos = drops_pasados + drops_futuros
    for alcance in C.ALCANCES:
        serie = C.serie_semanal(items, alcance, FECHA_CORTE)
        X, y = C.matriz_p1(serie, drops_pasados)
        Xtr, ytr, Xte, yte = X.iloc[:-SEMANAS_PRUEBA], y.iloc[:-SEMANAS_PRUEBA], X.iloc[-SEMANAS_PRUEBA:], y.iloc[-SEMANAS_PRUEBA:]
        cv = TimeSeriesSplit(n_splits=5)
        por_modelo, pred_prueba = {}, {}
        for nombre, modelo in modelos_p1().items():
            cv_rmse = -cross_val_score(modelo, Xtr, ytr, cv=cv, scoring="neg_root_mean_squared_error").mean()
            modelo.fit(Xtr, ytr)
            p = modelo.predict(Xte)
            pred_prueba[nombre] = [_r(v, 2) for v in p]
            por_modelo[nombre] = {"CV_RMSE": _r(cv_rmse, 3), **metricas_regresion(yte, p)}
        ganador = min(por_modelo, key=lambda n: por_modelo[n]["CV_RMSE"])
        sigma = por_modelo[ganador]["RMSE"]
        finales = {n: m.fit(X, y) for n, m in modelos_p1().items()}
        resultado[alcance] = {
            "serie": serie, "modelos": finales, "ganador": ganador, "sigma": sigma,
            "prueba": {"fechas": [d.isoformat() for d in yte.index], "real": yte.tolist(), "predicciones": pred_prueba},
            "metricas": por_modelo, "mapa_calor": mapa_calor(items, alcance),
        }
        metricas[alcance] = {"ganador": ganador, "semanas_entrenamiento": len(Xtr), "semanas_prueba": len(Xte),
                             "modelos": por_modelo}
        print(f"  P1 {alcance:<11} ganador: {ganador:<18} RMSE prueba {por_modelo[ganador]['RMSE']}")
    resultado["_drops"] = {"pasados": drops_pasados, "futuros": drops_futuros, "todos": drops_todos}
    return resultado, metricas


# ───────────────────────────── P2 · recompra ─────────────────────────────
def preprocesador_p2():
    numerico = Pipeline([("log", FunctionTransformer(np.log1p)), ("escala", StandardScaler())])
    return ColumnTransformer([
        ("num", numerico, C.FEATURES_P2_NUM),
        ("cat", OneHotEncoder(categories=[C.METODOS], handle_unknown="ignore"), C.FEATURES_P2_CAT),
    ])


def modelos_p2():
    return {
        "Regresión logística": Pipeline([("prep", preprocesador_p2()),
                                         ("modelo", LogisticRegression(class_weight="balanced", max_iter=2000))]),
        "Random Forest": Pipeline([("prep", preprocesador_p2()),
                                   ("modelo", RandomForestClassifier(n_estimators=400, min_samples_leaf=5,
                                                                     class_weight="balanced_subsample",
                                                                     random_state=SEMILLA, n_jobs=-1))]),
        "Red neuronal (MLP)": Pipeline([("prep", preprocesador_p2()),
                                        ("modelo", MLPClassifier(hidden_layer_sizes=(32, 16), alpha=1e-3,
                                                                 max_iter=800, early_stopping=True,
                                                                 random_state=SEMILLA))]),
    }


def entrenar_p2(peds):
    cortes = list(pd.date_range("2025-01-01", "2026-08-01", freq="MS"))
    ds = C.dataset_recompra(peds, cortes)
    cols = C.FEATURES_P2_NUM + C.FEATURES_P2_CAT
    tr, te = ds[ds["corte"] < CORTE_PRUEBA_P2], ds[ds["corte"] >= CORTE_PRUEBA_P2]
    cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=SEMILLA)
    por_modelo, rocs, matrices = {}, {}, {}
    for nombre, modelo in modelos_p2().items():
        cv_auc = cross_val_score(modelo, tr[cols], tr["recompra"], cv=cv, scoring="roc_auc").mean()
        modelo.fit(tr[cols], tr["recompra"])
        prob = modelo.predict_proba(te[cols])[:, 1]
        pred = (prob >= 0.5).astype(int)
        fpr, tpr, _ = roc_curve(te["recompra"], prob)
        idx = np.unique(np.linspace(0, len(fpr) - 1, min(60, len(fpr))).astype(int))
        rocs[nombre] = {"fpr": [_r(v, 4) for v in fpr[idx]], "tpr": [_r(v, 4) for v in tpr[idx]]}
        matrices[nombre] = confusion_matrix(te["recompra"], pred, labels=[0, 1]).tolist()
        por_modelo[nombre] = {
            "CV_ROC_AUC": _r(cv_auc), "ROC_AUC": _r(roc_auc_score(te["recompra"], prob)),
            "accuracy": _r(accuracy_score(te["recompra"], pred)), "precision": _r(precision_score(te["recompra"], pred)),
            "recall": _r(recall_score(te["recompra"], pred)), "F1": _r(f1_score(te["recompra"], pred)),
        }
        print(f"  P2 {nombre:<20} ROC-AUC prueba {por_modelo[nombre]['ROC_AUC']}")
    ganador = max(por_modelo, key=lambda n: por_modelo[n]["CV_ROC_AUC"])
    # Importancia por permutación del ganador, sobre los datos de prueba.
    modelo_g = modelos_p2()[ganador].fit(tr[cols], tr["recompra"])
    imp = permutation_importance(modelo_g, te[cols], te["recompra"], scoring="roc_auc", n_repeats=10,
                                 random_state=SEMILLA, n_jobs=-1)
    importancia = sorted(({"variable": c, "importancia": _r(m), "desviacion": _r(s)}
                          for c, m, s in zip(cols, imp.importances_mean, imp.importances_std)),
                         key=lambda d: -d["importancia"])
    finales = {n: m.fit(ds[cols], ds["recompra"]) for n, m in modelos_p2().items()}
    resumen = {
        "ganador": ganador, "filas_entrenamiento": len(tr), "filas_prueba": len(te),
        "tasa_recompra_entrenamiento": _r(tr["recompra"].mean()), "tasa_recompra_prueba": _r(te["recompra"].mean()),
        "cortes": [c.date().isoformat() for c in cortes], "corte_prueba_desde": CORTE_PRUEBA_P2.date().isoformat(),
        "modelos": por_modelo, "importancia_variables": importancia,
    }
    rangos = {c: {"min": _r(ds[c].min(), 2), "p50": _r(ds[c].median(), 2), "p95": _r(ds[c].quantile(.95), 2)}
              for c in C.FEATURES_P2_NUM}
    artefacto = {"modelos": finales, "ganador": ganador, "metricas": por_modelo, "roc": rocs,
                 "matrices": matrices, "importancia": importancia, "rangos": rangos}
    return artefacto, resumen, ds


# ───────────────────────────── P3 · segmentos ─────────────────────────────
def nombrar_segmentos(medias: pd.DataFrame) -> tuple[dict, list]:
    """Nombre de cada grupo según sus rasgos (no por posición):
    1) Premium: mayor valor = frecuencia × ticket, castigado por la inactividad.
    2) En riesgo: entre los demás, el de mayor recencia (más tiempo sin comprar).
    3) Ocasionales: entre los demás, el de menor ticket.
    4) Regulares: los que queden.
    Devuelve (nombre por grupo, grupos ordenados de menor a mayor valor)."""
    valor = medias["frecuencia_anual"] * medias["ticket_promedio"] / (1 + medias["recencia_dias"] / 90)
    restantes = list(medias.index)
    nombres = {}
    premium = valor.idxmax()
    nombres[premium] = "Premium"
    restantes.remove(premium)
    if len(restantes) >= 2:
        riesgo = medias.loc[restantes, "recencia_dias"].idxmax()
        nombres[riesgo] = "En riesgo"
        restantes.remove(riesgo)
    if restantes:
        ocasional = medias.loc[restantes, "ticket_promedio"].idxmin()
        nombres[ocasional] = "Ocasionales"
        restantes.remove(ocasional)
    for i, g in enumerate(sorted(restantes, key=lambda g: valor[g])):
        nombres[g] = "Regulares" if i == 0 else f"Regulares {i + 1}"
    return nombres, list(valor.sort_values().index)


def entrenar_p3(peds):
    perfil = C.perfil_clientes(peds, pd.Timestamp(FECHA_CORTE))
    escala = StandardScaler().fit(C.transformar_p3(perfil))
    Xs = escala.transform(C.transformar_p3(perfil))
    codo = []
    for k in range(2, 9):
        km = KMeans(n_clusters=k, n_init=20, random_state=SEMILLA).fit(Xs)
        codo.append({"k": k, "inercia": _r(km.inertia_, 2), "silueta": _r(silhouette_score(Xs, km.labels_))})
    # k: mejor silueta entre 3 y 5 (rango con interpretación de negocio; se documenta en la justificación).
    candidatos = [c for c in codo if 3 <= c["k"] <= 5]
    k = max(candidatos, key=lambda c: c["silueta"])["k"]
    etiquetas = {
        "K-means": KMeans(n_clusters=k, n_init=20, random_state=SEMILLA).fit_predict(Xs),
        "Mezcla gaussiana (GMM)": GaussianMixture(n_components=k, covariance_type="full", n_init=5,
                                                  random_state=SEMILLA).fit(Xs).predict(Xs),
        "Jerárquico (Ward)": AgglomerativeClustering(n_clusters=k, linkage="ward").fit_predict(Xs),
    }
    por_modelo = {n: {"silueta": _r(silhouette_score(Xs, e)), "davies_bouldin": _r(davies_bouldin_score(Xs, e)),
                      "calinski_harabasz": _r(calinski_harabasz_score(Xs, e), 2)} for n, e in etiquetas.items()}
    ganador = max(por_modelo, key=lambda n: por_modelo[n]["silueta"])
    lab = etiquetas[ganador]
    centroides = np.array([Xs[lab == c].mean(axis=0) for c in range(k)])
    medias = perfil.assign(_g=lab).groupby("_g").mean(numeric_only=True)
    nombre_de, orden = nombrar_segmentos(medias)
    pca = PCA(n_components=2, random_state=SEMILLA).fit(Xs)
    puntos = pca.transform(Xs)
    # Perfil para el radar, normalizado 0–1 entre segmentos.
    radar_cols = {"Frecuencia": medias["frecuencia_anual"], "Ticket": medias["ticket_promedio"],
                  "Actividad": 1 / (1 + medias["recencia_dias"] / 30), "Unidades/pedido": medias["unidades_por_pedido"],
                  "Gasto total": medias["gasto_total"]}
    radar = {"ejes": list(radar_cols), "segmentos": []}
    for g in orden:
        radar["segmentos"].append({"segmento": nombre_de[g],
                                   "valores": [_r(radar_cols[e][g] / radar_cols[e].max(), 4) for e in radar_cols]})
    perfiles = []
    for g in orden:
        fila = medias.loc[g]
        perfiles.append({"segmento": nombre_de[g], "clientes": int((lab == g).sum()),
                         "frecuencia_anual": _r(fila["frecuencia_anual"], 2), "ticket_promedio": _r(fila["ticket_promedio"], 0),
                         "recencia_dias": _r(fila["recencia_dias"], 1), "unidades_por_pedido": _r(fila["unidades_por_pedido"], 2),
                         "gasto_total": _r(fila["gasto_total"], 0)})
    artefacto = {
        "k": k, "ganador": ganador, "escala": escala, "pca": pca, "centroides": centroides, "nombre_de": nombre_de,
        "orden": orden, "metricas": por_modelo, "codo": codo, "radar": radar, "perfiles": perfiles,
        "puntos": [{"x": _r(p[0], 4), "y": _r(p[1], 4), "segmento": nombre_de[int(g)]} for p, g in zip(puntos, lab)],
        "centroides_pca": [{"segmento": nombre_de[g], **dict(zip(["x", "y"], map(lambda v: _r(v, 4),
                                                                              pca.transform(centroides[[g]])[0])))}
                           for g in orden],
        "varianza_pca": [_r(v) for v in pca.explained_variance_ratio_],
        "rangos": {c: {"min": _r(perfil[c].min(), 2), "p50": _r(perfil[c].median(), 2), "p95": _r(perfil[c].quantile(.95), 2)}
                   for c in C.FEATURES_P3},
    }
    resumen = {"k_elegido": k, "ganador": ganador, "clientes": len(perfil), "modelos": por_modelo, "codo": codo,
               "perfiles": perfiles, "varianza_explicada_pca": artefacto["varianza_pca"]}
    for nombre, m in por_modelo.items():
        print(f"  P3 {nombre:<24} silueta {m['silueta']}")
    return artefacto, resumen, perfil.assign(segmento=[nombre_de[int(g)] for g in lab])


# ───────────────────────────── documentación ─────────────────────────────
def _tabla_md(filas: dict, columnas: list[str]) -> str:
    cab = "| Modelo | " + " | ".join(columnas) + " |\n|---|" + "---|" * len(columnas) + "\n"
    return cab + "".join(f"| {n} | " + " | ".join(str(v.get(c, "")) for c in columnas) + " |\n" for n, v in filas.items())


def escribir_resultados_md(meta, m1, m2, m3):
    lineas = [
        "# Resultados y comparación de modelos",
        "",
        f"> Generado automáticamente por `underlaw_ml/entrenar.py` el {meta['fecha']} "
        f"con datos leídos desde **{meta['fuente'].upper()}**. Datos **sintéticos** (ver `datos_sinteticos.md`).",
        f"> No editar a mano: se reescribe en cada entrenamiento.",
        "",
        "## P1 · Regresión: unidades vendidas por semana",
        f"Validación temporal: {SEMANAS_PRUEBA} semanas finales como prueba; selección del ganador por RMSE "
        "promedio en validación cruzada temporal (TimeSeriesSplit, 5 pliegues) sobre el entrenamiento.",
        "",
    ]
    for alcance, info in m1.items():
        lineas += [f"### Alcance: {alcance} — ganador **{info['ganador']}**", "",
                   _tabla_md(info["modelos"], ["CV_RMSE", "MAE", "RMSE", "MAPE_%", "R2"]), ""]
    lineas += [
        "## P2 · Clasificación: ¿volverá a comprar en 60 días?",
        f"Partición temporal: cortes mensuales; prueba desde {m2['corte_prueba_desde']}. "
        f"Filas: {m2['filas_entrenamiento']} entrenamiento / {m2['filas_prueba']} prueba. "
        f"Tasa de recompra: {m2['tasa_recompra_entrenamiento']} (entrenamiento) / {m2['tasa_recompra_prueba']} (prueba). "
        "Selección por ROC-AUC promedio en validación cruzada estratificada (5 pliegues).",
        "", f"Ganador: **{m2['ganador']}**", "",
        _tabla_md(m2["modelos"], ["CV_ROC_AUC", "ROC_AUC", "accuracy", "precision", "recall", "F1"]), "",
        "Importancia de variables (permutación sobre prueba, caída del ROC-AUC):", "",
        "| Variable | Importancia | Desviación |\n|---|---|---|",
        *[f"| {i['variable']} | {i['importancia']} | {i['desviacion']} |" for i in m2["importancia_variables"]], "",
        "## P3 · Clustering: segmentos de clientes",
        f"k elegido: **{m3['k_elegido']}** (mejor silueta entre 3 y 5). Clientes: {m3['clientes']}. "
        f"Ganador por silueta: **{m3['ganador']}**.", "",
        _tabla_md(m3["modelos"], ["silueta", "davies_bouldin", "calinski_harabasz"]), "",
        "Curva del codo y silueta (K-means):", "", "| k | Inercia | Silueta |\n|---|---|---|",
        *[f"| {c['k']} | {c['inercia']} | {c['silueta']} |" for c in m3["codo"]], "",
        "Perfil de cada segmento:", "",
        "| Segmento | Clientes | Compras/año | Ticket promedio | Recencia (días) | Unidades/pedido | Gasto total |",
        "|---|---|---|---|---|---|---|",
        *[f"| {p['segmento']} | {p['clientes']} | {p['frecuencia_anual']} | {p['ticket_promedio']} | "
          f"{p['recencia_dias']} | {p['unidades_por_pedido']} | {p['gasto_total']} |" for p in m3["perfiles"]],
        "",
    ]
    (DIR_DOCS / "resultados_metricas.md").write_text("\n".join(lineas), encoding="utf-8")


def main(fuente: str | None = None):
    inicio = time.time()
    tablas, usada = cargar(fuente) if fuente else cargar()
    items = items_aprobados(tablas)
    peds = C.pedidos(items)
    pasados, futuros = fechas_drops(tablas)
    print(f"Datos: {usada.upper()} · {len(peds)} pedidos aprobados · {len(items)} ítems")

    a1, m1 = entrenar_p1(items, pasados, futuros)
    a2, m2, ds2 = entrenar_p2(peds)
    a3, m3, perfil = entrenar_p3(peds)

    DIR_MODELOS.mkdir(parents=True, exist_ok=True)
    meta = {"fecha": datetime.now().strftime("%Y-%m-%d %H:%M"), "fuente": usada, "fecha_corte": FECHA_CORTE.isoformat(),
            "pedidos_aprobados": len(peds), "items": len(items)}
    joblib.dump({"meta": meta, "p1": a1, "p2": a2, "p3": a3}, DIR_MODELOS / "underlaw_modelos.joblib", compress=3)
    (DIR_MODELOS / "metricas.json").write_text(
        json.dumps({"meta": meta, "p1_demanda": m1, "p2_recompra": m2, "p3_segmentos": m3}, ensure_ascii=False, indent=2),
        encoding="utf-8")

    # Vistas finales de entrenamiento (evidencia para el informe).
    filas_p1 = []
    for alcance in C.ALCANCES:
        X, y = C.matriz_p1(a1[alcance]["serie"], pasados)
        filas_p1.append(X.assign(unidades=y, alcance=alcance).reset_index(names="semana"))
    pd.concat(filas_p1).to_csv(DIR_EXPORT / "entrenamiento_p1_demanda_semanal.csv", index=False)
    ds2.to_csv(DIR_EXPORT / "entrenamiento_p2_recompra.csv", index=False)
    perfil.reset_index(names="correo").to_csv(DIR_EXPORT / "entrenamiento_p3_clientes.csv", index=False)

    escribir_resultados_md(meta, m1, m2, m3)
    print(f"Listo en {time.time() - inicio:.1f} s. Modelos en models/, métricas en models/metricas.json "
          f"y docs/resultados_metricas.md")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
