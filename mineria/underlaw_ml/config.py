"""Rutas y configuración compartida.

Las credenciales de MySQL se leen SOLO del archivo .env (ver .env.example).
Nunca se escriben en el código.
"""
import os
from datetime import date
from pathlib import Path
from urllib.parse import quote_plus

from dotenv import load_dotenv

RAIZ = Path(__file__).resolve().parent.parent  # carpeta mineria/
load_dotenv(RAIZ / ".env")

DIR_DATA = RAIZ / "data"
DIR_EXPORT = DIR_DATA / "export"
DIR_SQL = RAIZ / "sql"
DIR_MODELOS = RAIZ / "models"
DIR_GRAFICAS = DIR_MODELOS / "graficas"
DIR_DOCS = RAIZ / "docs"

# Semilla única: con la misma semilla los datos y los modelos salen idénticos.
SEMILLA = 2026

# Periodo del historial sintético. La "fecha de corte" es el último día con
# datos: el modelo predice las semanas posteriores a ella.
FECHA_INICIO = date(2024, 10, 1)
FECHA_CORTE = date(2026, 9, 30)

# Origen de los datos para entrenar: "mysql", "csv" o "auto"
# (auto = MySQL si el .env tiene credenciales y la conexión funciona; si no, CSV).
FUENTE_DATOS = os.getenv("FUENTE_DATOS", "auto").lower()


def url_mysql() -> str | None:
    """URL de SQLAlchemy armada con las variables del .env, o None si faltan."""
    usuario = os.getenv("DB_USER")
    if not usuario:
        return None
    clave = quote_plus(os.getenv("DB_PASSWORD", ""))
    host = os.getenv("DB_HOST", "localhost")
    puerto = os.getenv("DB_PORT", "3306")
    nombre = os.getenv("DB_NAME", "underlaw_mineria")
    return f"mysql+pymysql://{usuario}:{clave}@{host}:{puerto}/{nombre}?charset=utf8mb4"
