"""Lectura de datos para minería: desde MySQL (fuente principal) o desde CSV.

MySQL es la fuente de verdad. Los CSV de data/export son una copia exacta que
se usa si MySQL no está disponible (por ejemplo, antes de cargar la base o en
un despliegue en la nube). Ambos caminos devuelven las mismas columnas.
"""
import pandas as pd

from .config import DIR_EXPORT, FUENTE_DATOS, url_mysql

TABLAS = ["secciones", "catalogo_productos", "lanzamientos", "producto", "pedido_items", "direccion"]
COLUMNAS_FECHA = {
    "producto": ["fecha_compra"],
    "lanzamientos": ["fecha_lanzamiento", "created_at"],
    "catalogo_productos": ["fecha_creacion"],
    "direccion": ["fecha_registro"],
}


def _desde_mysql() -> dict:
    from sqlalchemy import create_engine

    url = url_mysql()
    if not url:
        raise RuntimeError("El .env no tiene DB_USER: no hay credenciales de MySQL.")
    motor = create_engine(url)
    with motor.connect() as con:
        tablas = {t: pd.read_sql(f"SELECT * FROM {t}", con) for t in TABLAS}
        # La vista de minería se arma en SQL (ver sql/01_esquema.sql).
        tablas["v_mineria_items"] = pd.read_sql("SELECT * FROM v_mineria_items", con)
    return tablas


def _desde_csv() -> dict:
    tablas = {}
    for t in TABLAS:
        ruta = DIR_EXPORT / f"{t}.csv"
        if not ruta.exists():
            raise FileNotFoundError(f"Falta {ruta}. Corre primero: python -m underlaw_ml.generar_datos")
        tablas[t] = pd.read_csv(ruta)
    return tablas


def _normalizar(tablas: dict) -> dict:
    for t, cols in COLUMNAS_FECHA.items():
        for c in cols:
            if t in tablas and c in tablas[t]:
                tablas[t][c] = pd.to_datetime(tablas[t][c])
    for t, cols in {"catalogo_productos": ["precio"], "producto": ["precio_producto"]}.items():
        for c in cols:
            tablas[t][c] = tablas[t][c].astype(float)  # DECIMAL de MySQL llega como Decimal
    return tablas


def items_aprobados(tablas: dict) -> pd.DataFrame:
    """Equivalente en pandas a la vista SQL v_mineria_items."""
    if "v_mineria_items" in tablas:
        v = tablas["v_mineria_items"].copy()
        v["fecha_compra"] = pd.to_datetime(v["fecha_compra"])
        for c in ["precio_unitario", "subtotal"]:
            v[c] = v[c].astype(float)
        return v.sort_values(["fecha_compra", "item_id"]).reset_index(drop=True)
    p = tablas["producto"]
    p = p[p["estado_pago"] == "APPROVED"]
    cat = tablas["catalogo_productos"].merge(
        tablas["secciones"][["id", "nombre"]].rename(columns={"id": "seccion_id", "nombre": "seccion"}),
        on="seccion_id", how="left")
    v = (tablas["pedido_items"].rename(columns={"id": "item_id"})
         .merge(p[["id", "fecha_compra", "correo_cliente", "metodo_pago"]].rename(columns={"id": "pedido_id"}),
                on="pedido_id", how="inner")
         .merge(tablas["direccion"][["pedido_id", "ciudad"]], on="pedido_id", how="left")
         .merge(cat[["id", "nombre_producto", "nombre_lanzamiento", "seccion", "precio"]]
                .rename(columns={"id": "producto_id", "nombre_producto": "nombre_catalogo", "precio": "precio_unitario"}),
                on="producto_id", how="left"))
    v["nombre_producto"] = v["nombre_catalogo"]
    v["subtotal"] = v["cantidad"] * v["precio_unitario"]
    cols = ["item_id", "pedido_id", "fecha_compra", "correo_cliente", "metodo_pago", "ciudad", "producto_id",
            "nombre_producto", "nombre_lanzamiento", "seccion", "talla", "cantidad", "precio_unitario", "subtotal"]
    return v[cols].sort_values(["fecha_compra", "item_id"]).reset_index(drop=True)


def cargar(fuente: str = FUENTE_DATOS) -> tuple[dict, str]:
    """Devuelve (tablas, fuente_usada). fuente: 'mysql', 'csv' o 'auto'."""
    if fuente in ("mysql", "auto"):
        try:
            return _normalizar(_desde_mysql()), "mysql"
        except Exception as error:  # noqa: BLE001 - en 'auto' se informa y se usa CSV
            if fuente == "mysql":
                raise
            print(f"[datos] MySQL no disponible ({type(error).__name__}: {error}). Se usan los CSV de data/export.")
    return _normalizar(_desde_csv()), "csv"
