"""Construcción de variables (features). Lo usan el entrenamiento y el servicio,
así una predicción se calcula exactamente igual que durante la evaluación."""
from datetime import date, timedelta

import numpy as np
import pandas as pd
from sklearn.base import BaseEstimator, RegressorMixin, clone

# ───────────────────────────── P1 · demanda semanal ─────────────────────────────
ALCANCES = ["todas", "Camisetas", "Hoodies", "Pantalones", "Accesorios"]
N_REZAGOS = 4
FEATURES_P1 = [
    "rezago_1", "rezago_2", "rezago_3", "rezago_4", "media_movil_4",
    "semana_sin", "semana_cos", "temporada_alta", "black_friday", "diciembre", "inicio_anio",
    "drop_semana", "drop_semana_anterior", "semanas_desde_drop", "efecto_drop", "tendencia",
]


def lunes(d) -> date:
    d = pd.Timestamp(d).date()
    return d - timedelta(days=d.weekday())


def serie_semanal(items: pd.DataFrame, alcance: str, fecha_fin: date) -> pd.Series:
    """Unidades vendidas por semana (lunes a domingo), solo semanas completas."""
    datos = items if alcance == "todas" else items[items["seccion"] == alcance]
    semana = datos["fecha_compra"].dt.date.map(lunes)
    serie = datos.groupby(semana)["cantidad"].sum()
    primera = lunes(items["fecha_compra"].min()) + timedelta(weeks=1)   # se descarta la 1.ª semana incompleta
    ultima = lunes(fecha_fin) - timedelta(weeks=1) if lunes(fecha_fin) + timedelta(days=6) > fecha_fin else lunes(fecha_fin)
    indice = [primera + timedelta(weeks=i) for i in range((ultima - primera).days // 7 + 1)]
    return serie.reindex(indice, fill_value=0).astype(float)


def _black_friday(anio: int) -> date:
    d = date(anio, 11, 1)
    while d.weekday() != 3:
        d += timedelta(days=1)
    return d + timedelta(weeks=3, days=1)


def calendario(semana: date, drops: list[date], origen: date) -> dict:
    fin = semana + timedelta(days=6)
    iso = semana.isocalendar().week
    bf = _black_friday(semana.year)
    return {
        "semana_sin": float(np.sin(2 * np.pi * iso / 52)),
        "semana_cos": float(np.cos(2 * np.pi * iso / 52)),
        "temporada_alta": float((semana.month == 11 and semana.day >= 15) or semana.month == 12),
        "black_friday": float(semana <= bf <= fin),
        "diciembre": float(semana.month == 12),
        "inicio_anio": float(semana.month in (1, 2)),
        "drop_semana": float(any(semana <= d <= fin for d in drops)),
        "drop_semana_anterior": float(any(semana - timedelta(days=7) <= d < semana for d in drops)),
        # Cuánto pesa todavía el último drop: el pico de ventas se apaga en ~3-4 semanas.
        "semanas_desde_drop": float(min(8, min(((fin - d).days // 7 for d in drops if d <= fin), default=8))),
        "efecto_drop": float(np.mean([sum(np.exp(-(dia - d).days / 7) for d in drops if 0 <= (dia - d).days <= 42)
                                      for dia in (semana + timedelta(days=i) for i in range(7))])),
        "tendencia": (semana - origen).days / 365.0,
    }


def fila_p1(semana: date, historial: list[float], drops: list[date], origen: date) -> dict:
    rez = historial[-N_REZAGOS:][::-1]
    fila = {f"rezago_{i + 1}": rez[i] for i in range(N_REZAGOS)}
    fila["media_movil_4"] = float(np.mean(rez))
    fila.update(calendario(semana, drops, origen))
    return fila


def matriz_p1(serie: pd.Series, drops: list[date]) -> tuple[pd.DataFrame, pd.Series]:
    origen = serie.index[0]
    filas, y, fechas = [], [], []
    valores = serie.tolist()
    for i in range(N_REZAGOS, len(valores)):
        filas.append(fila_p1(serie.index[i], valores[:i], drops, origen))
        y.append(valores[i])
        fechas.append(serie.index[i])
    return pd.DataFrame(filas, index=fechas)[FEATURES_P1], pd.Series(y, index=fechas)


class ModeloRelativo(BaseEstimator, RegressorMixin):
    """Envuelve un regresor para que aprenda el cambio relativo frente al nivel
    reciente: objetivo = log(1 + y) - log(1 + media_movil_4).

    Motivo: la tienda crece en el tiempo y los modelos de árboles no pueden
    predecir valores por encima de lo que vieron al entrenar. Modelando la
    variación respecto a las últimas 4 semanas, cualquier modelo sigue la
    tendencia. Se aplica igual a los tres modelos para que la comparación sea justa.
    """

    def __init__(self, base=None):
        self.base = base

    def fit(self, X, y):
        nivel = np.log1p(np.asarray(X["media_movil_4"], dtype=float))
        self.base_ = clone(self.base).fit(X, np.log1p(np.asarray(y, dtype=float)) - nivel)
        return self

    def predict(self, X):
        nivel = np.log1p(np.asarray(X["media_movil_4"], dtype=float))
        return np.expm1(self.base_.predict(X) + nivel)


def pronosticar_p1(modelo, serie: pd.Series, semanas: int, drops: list[date]) -> list[tuple[date, float]]:
    """Pronóstico recursivo: cada semana predicha alimenta los rezagos de la siguiente."""
    origen = serie.index[0]
    historial = serie.tolist()
    semana = serie.index[-1] + timedelta(weeks=1)
    salida = []
    for _ in range(semanas):
        x = pd.DataFrame([fila_p1(semana, historial, drops, origen)])[FEATURES_P1]
        valor = max(0.0, float(modelo.predict(x)[0]))
        salida.append((semana, valor))
        historial.append(valor)
        semana += timedelta(weeks=1)
    return salida


# ──────────────────────── pedidos y clientes (P2 y P3) ────────────────────────
def pedidos(items: pd.DataFrame) -> pd.DataFrame:
    """Una fila por pedido aprobado: fecha, cliente, total, unidades y método de pago."""
    return (items.groupby("pedido_id")
            .agg(fecha=("fecha_compra", "first"), correo=("correo_cliente", "first"),
                 total=("subtotal", "sum"), unidades=("cantidad", "sum"), metodo_pago=("metodo_pago", "first"))
            .reset_index())


METODOS = ["CARD", "PSE", "NEQUI"]
FEATURES_P2_NUM = ["recencia_dias", "frecuencia", "ticket_promedio", "monto_total", "antiguedad_dias"]
FEATURES_P2_CAT = ["metodo_pago"]
VENTANA_RECOMPRA = 60


def rfm_al_corte(peds: pd.DataFrame, corte: pd.Timestamp) -> pd.DataFrame:
    """Variables de cada cliente usando SOLO lo ocurrido antes del corte."""
    previos = peds[peds["fecha"] < corte]
    g = previos.groupby("correo")
    tabla = pd.DataFrame({
        "recencia_dias": (corte - g["fecha"].max()).dt.days,
        "frecuencia": g.size(),
        "ticket_promedio": g["total"].mean(),
        "monto_total": g["total"].sum(),
        "antiguedad_dias": (corte - g["fecha"].min()).dt.days,
        "metodo_pago": g["metodo_pago"].agg(lambda s: s.mode().iat[0]),
    })
    return tabla


def dataset_recompra(peds: pd.DataFrame, cortes: list[pd.Timestamp]) -> pd.DataFrame:
    partes = []
    for corte in cortes:
        x = rfm_al_corte(peds, corte)
        futuros = peds[(peds["fecha"] >= corte) & (peds["fecha"] < corte + pd.Timedelta(days=VENTANA_RECOMPRA))]
        x["recompra"] = x.index.isin(futuros["correo"]).astype(int)
        x["corte"] = corte
        partes.append(x.reset_index())
    return pd.concat(partes, ignore_index=True)


FEATURES_P3 = ["frecuencia_anual", "ticket_promedio", "recencia_dias"]


def perfil_clientes(peds: pd.DataFrame, corte: pd.Timestamp) -> pd.DataFrame:
    """Perfil de cada cliente a la fecha de corte (para segmentación)."""
    g = peds[peds["fecha"] <= corte].groupby("correo")
    dias_activo = (corte - g["fecha"].min()).dt.days.clip(lower=90)
    return pd.DataFrame({
        "frecuencia_anual": g.size() * 365.0 / dias_activo,
        "ticket_promedio": g["total"].mean(),
        "recencia_dias": (corte - g["fecha"].max()).dt.days.astype(float),
        "unidades_por_pedido": g["unidades"].mean(),
        "gasto_total": g["total"].sum(),
        "pedidos": g.size(),
    })


def transformar_p3(df: pd.DataFrame) -> np.ndarray:
    """Escala logarítmica: frecuencia y ticket tienen colas largas."""
    return np.column_stack([
        np.log1p(df["frecuencia_anual"].to_numpy(dtype=float)),
        np.log(df["ticket_promedio"].to_numpy(dtype=float)),
        np.log1p(df["recencia_dias"].to_numpy(dtype=float)),
    ])
