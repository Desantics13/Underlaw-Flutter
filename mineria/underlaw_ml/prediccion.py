"""Ejecución de predicciones con los modelos ya entrenados.

El servicio (service/app.py) llama a estas funciones cada vez que la app pulsa
PREDECIR: el modelo se ejecuta en ese momento con los valores recibidos.
No necesita la base de datos: todo lo necesario está en models/underlaw_modelos.joblib.
"""
import math
import uuid
from datetime import datetime, timedelta

import joblib
import numpy as np
import pandas as pd

from . import caracteristicas as C
from .config import DIR_MODELOS

Z80, Z95 = 1.2816, 1.96
METODO_ETIQUETA = {"CARD": "tarjeta", "PSE": "PSE", "NEQUI": "Nequi"}


class ErrorValidacion(ValueError):
    """Valores inválidos enviados por la app (el servicio responde 400)."""


def numero(v: float, decimales: int = 0) -> str:
    """Formato colombiano: punto de miles y coma decimal."""
    texto = f"{v:,.{decimales}f}"
    return texto.replace(",", "_").replace(".", ",").replace("_", ".")


def dinero(v: float) -> str:
    return "$" + numero(v)


VARIABLE_ETIQUETA = {"recencia_dias": "días desde la última compra", "frecuencia": "número de compras",
                     "ticket_promedio": "ticket promedio", "monto_total": "monto total comprado",
                     "antiguedad_dias": "antigüedad como cliente", "metodo_pago": "método de pago"}


# ───────────────────────────── catálogo de oraciones ─────────────────────────────
CATALOGO = [
    {
        "id": "demanda",
        "titulo": "Demanda de las próximas semanas",
        "tipo_problema": "Regresión (serie de tiempo)",
        "plantilla": "¿Cuántas unidades de {alcance} se venderán en {semanas}, {escenario}?",
        "campos": [
            {"id": "alcance", "tipo": "opcion", "etiqueta": "Prendas", "defecto": "todas",
             "opciones": [{"valor": "todas", "etiqueta": "todas las prendas"},
                          {"valor": "Camisetas", "etiqueta": "camisetas"}, {"valor": "Hoodies", "etiqueta": "hoodies"},
                          {"valor": "Pantalones", "etiqueta": "pantalones"},
                          {"valor": "Accesorios", "etiqueta": "accesorios"}]},
            {"id": "semanas", "tipo": "entero", "etiqueta": "Semanas", "min": 1, "max": 12, "paso": 1, "defecto": 4,
             "formato": {"singular": "la próxima semana", "plural": "las próximas {n} semanas"}},
            {"id": "escenario", "tipo": "opcion", "etiqueta": "Escenario", "defecto": "con_drop",
             "opciones": [{"valor": "con_drop", "etiqueta": "contando el drop programado"},
                          {"valor": "sin_drop", "etiqueta": "sin lanzamientos nuevos"}]},
        ],
    },
    {
        "id": "recompra",
        "titulo": "Probabilidad de recompra",
        "tipo_problema": "Clasificación binaria",
        "plantilla": "¿Un cliente con {frecuencia}, ticket promedio de {ticket_promedio}, última compra hace "
                     "{recencia_dias}, {antiguedad_dias} como cliente y que paga con {metodo_pago} "
                     "volverá a comprar en los próximos 60 días?",
        "campos": [
            {"id": "frecuencia", "tipo": "entero", "etiqueta": "Compras", "min": 1, "max": 40, "paso": 1, "defecto": 3,
             "formato": {"singular": "1 compra", "plural": "{n} compras"}},
            {"id": "ticket_promedio", "tipo": "dinero", "etiqueta": "Ticket promedio", "min": 40000, "max": 1500000,
             "paso": 10000, "defecto": 250000},
            {"id": "recencia_dias", "tipo": "entero", "etiqueta": "Días desde la última compra", "min": 0, "max": 600,
             "paso": 5, "defecto": 30, "formato": {"singular": "1 día", "plural": "{n} días"}},
            {"id": "antiguedad_dias", "tipo": "entero", "etiqueta": "Días como cliente", "min": 0, "max": 730,
             "paso": 10, "defecto": 240, "formato": {"singular": "1 día", "plural": "{n} días"}},
            {"id": "metodo_pago", "tipo": "opcion", "etiqueta": "Método de pago", "defecto": "CARD",
             "opciones": [{"valor": k, "etiqueta": v} for k, v in METODO_ETIQUETA.items()]},
        ],
    },
    {
        "id": "segmento",
        "titulo": "Segmento del cliente",
        "tipo_problema": "Clustering (aprendizaje no supervisado)",
        "plantilla": "¿A qué segmento pertenece un cliente con {frecuencia_anual}, ticket promedio de "
                     "{ticket_promedio} y última compra hace {recencia_dias}?",
        "campos": [
            {"id": "frecuencia_anual", "tipo": "entero", "etiqueta": "Compras al año", "min": 1, "max": 40, "paso": 1,
             "defecto": 6, "formato": {"singular": "1 compra al año", "plural": "{n} compras al año"}},
            {"id": "ticket_promedio", "tipo": "dinero", "etiqueta": "Ticket promedio", "min": 40000, "max": 1500000,
             "paso": 10000, "defecto": 300000},
            {"id": "recencia_dias", "tipo": "entero", "etiqueta": "Días desde la última compra", "min": 0, "max": 730,
             "paso": 5, "defecto": 30, "formato": {"singular": "1 día", "plural": "{n} días"}},
        ],
    },
]
_POR_ID = {p["id"]: p for p in CATALOGO}


def validar(id_pred: str, valores: dict) -> dict:
    if id_pred not in _POR_ID:
        raise KeyError(id_pred)
    limpios, errores = {}, []
    for campo in _POR_ID[id_pred]["campos"]:
        cid = campo["id"]
        v = valores.get(cid, campo["defecto"])
        if campo["tipo"] == "opcion":
            permitidos = [o["valor"] for o in campo["opciones"]]
            if v not in permitidos:
                errores.append(f"'{cid}' debe ser uno de: {', '.join(permitidos)}")
        else:
            try:
                v = int(v)
            except (TypeError, ValueError):
                errores.append(f"'{cid}' debe ser un número entero")
                continue
            if not campo["min"] <= v <= campo["max"]:
                errores.append(f"'{cid}' debe estar entre {campo['min']} y {campo['max']}")
        limpios[cid] = v
    desconocidos = set(valores) - {c["id"] for c in _POR_ID[id_pred]["campos"]}
    if desconocidos:
        errores.append(f"campos no reconocidos: {', '.join(sorted(desconocidos))}")
    if id_pred == "recompra" and not errores and limpios["recencia_dias"] > limpios["antiguedad_dias"]:
        errores.append("'recencia_dias' no puede ser mayor que 'antiguedad_dias'")
    if errores:
        raise ErrorValidacion("; ".join(errores))
    return limpios


def redactar(id_pred: str, valores: dict) -> str:
    textos = {}
    for campo in _POR_ID[id_pred]["campos"]:
        v = valores[campo["id"]]
        if campo["tipo"] == "opcion":
            textos[campo["id"]] = next(o["etiqueta"] for o in campo["opciones"] if o["valor"] == v)
        elif campo["tipo"] == "dinero":
            textos[campo["id"]] = dinero(v)
        elif "formato" in campo:
            textos[campo["id"]] = campo["formato"]["singular" if v == 1 else "plural"].replace("{n}", str(v))
        else:
            textos[campo["id"]] = str(v)
    return _POR_ID[id_pred]["plantilla"].format(**textos)


def _ultimas_semanas(mapa: dict, n: int) -> dict:
    """Recorta el mapa de calor a las n semanas más recientes (legible en el celular)."""
    return {**mapa, "semanas": mapa["semanas"][-n:], "valores": mapa["valores"][-n:]}


# ───────────────────────────── motor ─────────────────────────────
class Motor:
    def __init__(self, ruta=DIR_MODELOS / "underlaw_modelos.joblib"):
        if not ruta.exists():
            raise FileNotFoundError(f"No hay modelos entrenados en {ruta}. Corre: python -m underlaw_ml.entrenar")
        a = joblib.load(ruta)
        self.meta, self.p1, self.p2, self.p3 = a["meta"], a["p1"], a["p2"], a["p3"]

    def predecir(self, id_pred: str, valores: dict) -> dict:
        limpios = validar(id_pred, valores)
        funcion = {"demanda": self._demanda, "recompra": self._recompra, "segmento": self._segmento}[id_pred]
        resultado, graficas = funcion(limpios)
        base = {"id_prediccion": uuid.uuid4().hex[:12], "prediccion": id_pred,
                "titulo": _POR_ID[id_pred]["titulo"], "tipo_problema": _POR_ID[id_pred]["tipo_problema"],
                "pregunta": redactar(id_pred, limpios), "valores": limpios,
                "creada": datetime.now().isoformat(timespec="seconds"),
                "datos": {"origen": "sintéticos", "fecha_corte": self.meta["fecha_corte"],
                          "entrenado": self.meta["fecha"], "fuente_entrenamiento": self.meta["fuente"]}}
        base.update(resultado)
        referencia = {k: base[k] for k in ("id_prediccion", "prediccion", "titulo", "pregunta", "valores")}
        referencia["resultado"] = base["resultado"]["texto"]
        return {"respuesta": base, "graficas": {"referencia": referencia, "graficas": graficas}}

    # P1 ─ demanda
    def _demanda(self, v):
        info = self.p1[v["alcance"]]
        drops = self.p1["_drops"]
        usar = drops["pasados"] + (drops["futuros"] if v["escenario"] == "con_drop" else [])
        serie, n = info["serie"], v["semanas"]
        pron = {nombre: C.pronosticar_p1(m, serie, n, usar) for nombre, m in info["modelos"].items()}
        ganador = info["ganador"]
        puntos = pron[ganador]
        sigma = info["sigma"]
        total = sum(val for _, val in puntos)
        sd_total = sigma * math.sqrt(n)
        inf80, sup80 = max(0.0, total - Z80 * sd_total), total + Z80 * sd_total
        fin_horizonte = puntos[-1][0] + timedelta(days=6)
        drops_en_horizonte = [d for d in drops["futuros"] if puntos[0][0] <= d <= fin_horizonte]
        if v["escenario"] == "con_drop" and drops_en_horizonte:
            nota = f"Incluye el drop programado del {drops_en_horizonte[0]:%d/%m/%Y}."
        elif drops_en_horizonte:
            nota = "Se excluyó el drop programado que cae en este periodo."
        else:
            nota = "No hay drops programados dentro de este periodo."
        promedio_reciente = float(np.mean(serie.iloc[-8:]))
        cambio = (total / n - promedio_reciente) / promedio_reciente * 100 if promedio_reciente else 0
        resultado = {
            "resultado": {"valor": round(total), "unidad": "unidades", "texto": f"≈ {numero(total)} unidades",
                          "detalle": f"Entre {numero(inf80)} y {numero(sup80)} unidades (intervalo del 80 %). {nota}"},
            "intervalo": {"nivel": 0.8, "inferior": round(inf80), "superior": round(sup80)},
            "semanas": [{"semana": s.isoformat(), "unidades": round(val, 1)} for s, val in puntos],
            "modelo": {"nombre": ganador, "comparados": list(info["modelos"]),
                       "criterio": "Menor RMSE en validación cruzada temporal"},
            "metricas": info["metricas"][ganador],
            "explicacion": (f"El modelo {ganador} proyecta en promedio {total / n:.0f} unidades por semana, "
                            f"{'un' if cambio >= 0 else 'una'} {'aumento' if cambio >= 0 else 'caída'} de "
                            f"{abs(cambio):.0f} % frente a las últimas 8 semanas. "
                            f"En la prueba con datos que no vio, se equivocó en promedio "
                            f"{info['metricas'][ganador]['MAE']:.0f} unidades por semana."),
        }
        hist = serie.iloc[-52:]
        graficas = [
            {"id": "proyeccion", "tipo": "serie_proyeccion", "titulo": "Histórico y proyección",
             "descripcion": "Unidades por semana. Toca la leyenda para mostrar u ocultar modelos y "
                            "«Activar zoom» para pellizcar y desplazarte.",
             "historial": [{"fecha": d.isoformat(), "valor": float(x)} for d, x in hist.items()],
             "pronosticos": [{"modelo": nombre, "ganador": nombre == ganador,
                              "puntos": [{"fecha": s.isoformat(), "valor": round(val, 1)} for s, val in pts]}
                             for nombre, pts in pron.items()],
             "banda": [{"fecha": s.isoformat(), "inferior80": round(max(0, val - Z80 * sigma * math.sqrt(h)), 1),
                        "superior80": round(val + Z80 * sigma * math.sqrt(h), 1),
                        "inferior95": round(max(0, val - Z95 * sigma * math.sqrt(h)), 1),
                        "superior95": round(val + Z95 * sigma * math.sqrt(h), 1)}
                       for h, (s, val) in enumerate(puntos, start=1)],
             "drops": [d.isoformat() for d in usar if d >= hist.index[0]],
             "inicio_pronostico": puntos[0][0].isoformat()},
            {"id": "prueba", "tipo": "real_vs_predicho", "titulo": "Validación: real vs. predicho",
             "descripcion": f"Las {len(info['prueba']['fechas'])} semanas finales que los modelos no vieron al entrenar.",
             "fechas": info["prueba"]["fechas"], "real": info["prueba"]["real"],
             "modelos": [{"modelo": k, "ganador": k == ganador, "valores": vals}
                         for k, vals in info["prueba"]["predicciones"].items()]},
            {"id": "metricas", "tipo": "barras_metricas", "titulo": "Comparación de modelos",
             "descripcion": "Error en las semanas de prueba (más bajo es mejor).", "metricas": ["MAE", "RMSE", "MAPE_%"],
             "mejor_es": "menor",
             "modelos": [{"modelo": k, "ganador": k == ganador, "valores": {m: mv[m] for m in ["MAE", "RMSE", "MAPE_%"]}}
                         for k, mv in info["metricas"].items()]},
            {"id": "calor", "tipo": "mapa_calor", "titulo": "Ventas por día de la semana",
             "descripcion": "Unidades vendidas en las últimas 12 semanas (más intenso = más ventas).",
             **_ultimas_semanas(info["mapa_calor"], 12)},
        ]
        return resultado, graficas

    # P2 ─ recompra
    def _recompra(self, v):
        fila = pd.DataFrame([{**{k: v[k] for k in ["recencia_dias", "frecuencia", "ticket_promedio",
                                                   "antiguedad_dias", "metodo_pago"]},
                              "monto_total": v["frecuencia"] * v["ticket_promedio"]}])
        ganador = self.p2["ganador"]
        probs = {n: float(m.predict_proba(fila)[0, 1]) for n, m in self.p2["modelos"].items()}
        p = probs[ganador]
        si = p >= 0.5
        nivel = "alta" if p >= 0.7 else "media" if p >= 0.4 else "baja"
        recencias = list(range(0, 361, 15))
        curva = self.p2["modelos"][ganador].predict_proba(pd.concat(
            [fila.assign(recencia_dias=r, antiguedad_dias=max(v["antiguedad_dias"], r)) for r in recencias]))[:, 1]
        top_var = self.p2["importancia"][0]["variable"]
        top = VARIABLE_ETIQUETA.get(top_var, top_var)
        efecto = (": mientras más tiempo pasa sin comprar, menor la probabilidad de volver."
                  if top_var == "recencia_dias" else ".")
        resultado = {
            "resultado": {"valor": round(p, 4), "unidad": "probabilidad",
                          "texto": f"{'Sí' if si else 'No'} volvería a comprar · {p * 100:.0f} %",
                          "detalle": f"Probabilidad {nivel} de recompra en 60 días (umbral de decisión: 50 %)."},
            "probabilidad": round(p, 4), "clase": "recompra" if si else "no_recompra",
            "modelo": {"nombre": ganador, "comparados": list(self.p2["modelos"]),
                       "criterio": "Mayor ROC-AUC en validación cruzada"},
            "metricas": self.p2["metricas"][ganador],
            "explicacion": (f"Según {ganador}, la probabilidad es {p * 100:.0f} %. La variable que más pesa en este "
                            f"modelo es «{top}»{efecto}"),
        }
        graficas = [
            {"id": "medidor", "tipo": "medidor", "titulo": "Probabilidad de recompra",
             "descripcion": "Resultado del modelo ganador. La aguja marca la probabilidad; la línea, el umbral del 50 %.",
             "valor": round(p, 4), "umbral": 0.5, "clase": resultado["clase"]},
            {"id": "por_modelo", "tipo": "barras_probabilidad", "titulo": "Lo que dice cada modelo",
             "descripcion": "La misma consulta evaluada por los tres modelos comparados.",
             "modelos": [{"modelo": n, "ganador": n == ganador, "probabilidad": round(x, 4)} for n, x in probs.items()]},
            {"id": "sensibilidad", "tipo": "curva_sensibilidad", "titulo": "¿Y si pasa más tiempo sin comprar?",
             "descripcion": "Probabilidad según los días desde la última compra, dejando lo demás igual.",
             "eje_x": "Días desde la última compra", "puntos": [{"x": r, "y": round(float(y), 4)} for r, y in zip(recencias, curva)],
             "actual": {"x": v["recencia_dias"], "y": round(p, 4)}},
            {"id": "roc", "tipo": "curva_roc", "titulo": "Curva ROC (prueba)",
             "descripcion": "Qué tan bien separa cada modelo a quienes vuelven de quienes no. Más arriba a la izquierda es mejor.",
             "modelos": [{"modelo": n, "ganador": n == ganador, "auc": self.p2["metricas"][n]["ROC_AUC"], **curva_roc}
                         for n, curva_roc in self.p2["roc"].items()]},
            {"id": "matriz", "tipo": "matriz_confusion", "titulo": "Matriz de confusión (prueba)",
             "descripcion": f"Aciertos y errores de {ganador} con umbral del 50 %.",
             "etiquetas": ["No vuelve", "Vuelve"], "valores": self.p2["matrices"][ganador]},
            {"id": "importancia", "tipo": "importancia_variables", "titulo": "Importancia de las variables",
             "descripcion": "Cuánto empeora el modelo si se desordena cada variable (permutación).",
             "variables": [{**i, "etiqueta": VARIABLE_ETIQUETA.get(i["variable"], i["variable"])}
                           for i in self.p2["importancia"]]},
        ]
        return resultado, graficas

    # P3 ─ segmento
    def _segmento(self, v):
        p3 = self.p3
        df = pd.DataFrame([{"frecuencia_anual": v["frecuencia_anual"], "ticket_promedio": v["ticket_promedio"],
                            "recencia_dias": v["recencia_dias"]}])
        x = p3["escala"].transform(C.transformar_p3(df))
        distancias = np.linalg.norm(p3["centroides"] - x, axis=1)
        g = int(np.argmin(distancias))
        nombre = p3["nombre_de"][g]
        punto = p3["pca"].transform(x)[0]
        perfil = next(pf for pf in p3["perfiles"] if pf["segmento"] == nombre)
        cercania = 1 / (1 + distancias)
        confianza = float(cercania[g] / cercania.sum())
        resultado = {
            "resultado": {"valor": nombre, "unidad": "segmento", "texto": f"Segmento: {nombre}",
                          "detalle": f"Se parece al grupo «{nombre}»: en promedio {numero(perfil['frecuencia_anual'], 1)} compras "
                                     f"al año y ticket de {dinero(perfil['ticket_promedio'])}."},
            "segmento": nombre, "afinidad": round(confianza, 4),
            "distancias": {p3["nombre_de"][i]: round(float(d), 4) for i, d in enumerate(distancias)},
            "modelo": {"nombre": p3["ganador"], "comparados": list(p3["metricas"]),
                       "criterio": f"Mayor coeficiente de silueta (k = {p3['k']})"},
            "metricas": p3["metricas"][p3["ganador"]],
            "explicacion": (f"El cliente queda más cerca del centro del grupo «{nombre}» "
                            f"(afinidad {confianza * 100:.0f} % frente a los demás grupos). "
                            f"Ese grupo reúne {perfil['clientes']} clientes."),
        }
        graficas = [
            {"id": "mapa_clientes", "tipo": "dispersion_clusters", "titulo": "Mapa de clientes",
             "descripcion": "Cada punto es un cliente (proyección PCA de sus 3 variables). El rombo dorado es esta consulta. "
                            "Toca un punto para ver su grupo y usa «Activar zoom» para acercarte.",
             "varianza_explicada": p3["varianza_pca"], "puntos": p3["puntos"], "centroides": p3["centroides_pca"],
             "consulta": {"x": round(float(punto[0]), 4), "y": round(float(punto[1]), 4), "segmento": nombre}},
            {"id": "radar", "tipo": "radar_segmentos", "titulo": "Perfil de cada segmento",
             "descripcion": "Valores relativos entre segmentos (1 = el más alto).", **p3["radar"], "resaltado": nombre},
            {"id": "codo", "tipo": "codo_silueta", "titulo": "¿Cuántos grupos?",
             "descripcion": "Inercia (codo) y silueta de K-means para k = 2…8.", "k_elegido": p3["k"], "puntos": p3["codo"]},
            {"id": "metricas", "tipo": "barras_metricas", "titulo": "Comparación de algoritmos",
             "descripcion": "Silueta: más alto es mejor. Davies-Bouldin: más bajo es mejor.",
             "metricas": ["silueta", "davies_bouldin"], "mejor_es": {"silueta": "mayor", "davies_bouldin": "menor"},
             "modelos": [{"modelo": k, "ganador": k == p3["ganador"],
                          "valores": {m: mv[m] for m in ["silueta", "davies_bouldin"]}} for k, mv in p3["metricas"].items()]},
        ]
        return resultado, graficas
