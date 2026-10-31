"""Servicio de predicción de UnderLaw (FastAPI).

Es un microservicio independiente del backend Node de la tienda: no toca la
base de producción ni la web. Carga los modelos entrenados y ejecuta cada
predicción en el momento en que la app la pide.

Levantar (desde mineria/):
    venv\\Scripts\\uvicorn service.app:app --host 0.0.0.0 --port 8000
Documentación interactiva: http://localhost:8000/docs
"""
import logging
import os
from collections import OrderedDict

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

from underlaw_ml.prediccion import CATALOGO, ErrorValidacion, Motor

log = logging.getLogger("underlaw.service")

app = FastAPI(
    title="UnderLaw · Servicio de predicción",
    version="1.0.0",
    description="Predicciones de minería de datos (demanda, recompra y segmentación) para la app móvil. "
                "Los modelos se entrenaron con datos sintéticos.",
)

origenes = [o.strip() for o in os.getenv("CORS_ORIGENES", "http://localhost:3000").split(",") if o.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origenes,
    # Flutter web en desarrollo puede usar cualquier puerto de localhost.
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

motor = Motor()
# Últimas predicciones en memoria, para que /graficas/{id} conserve la referencia.
_PREDICCIONES: "OrderedDict[str, dict]" = OrderedDict()
_MAX_GUARDADAS = 300


class Peticion(BaseModel):
    valores: dict = Field(default_factory=dict, description="Valores de los campos de la oración.")


def _error(codigo: int, mensaje: str) -> JSONResponse:
    return JSONResponse(status_code=codigo, content={"error": mensaje, "codigo": codigo})


@app.exception_handler(ErrorValidacion)
async def _validacion(_: Request, exc: ErrorValidacion):
    return _error(400, str(exc))


@app.exception_handler(RequestValidationError)
async def _cuerpo_invalido(_: Request, exc: RequestValidationError):
    return _error(400, "El cuerpo de la petición no es válido: se espera {\"valores\": {...}}.")


@app.exception_handler(Exception)
async def _inesperado(_: Request, exc: Exception):
    log.exception("Error no controlado: %s", exc)
    return _error(500, "Error interno del servidor.")


@app.get("/health")
def health():
    return {"estado": "ok", "modelos_entrenados": motor.meta["fecha"], "fuente_entrenamiento": motor.meta["fuente"],
            "fecha_corte_datos": motor.meta["fecha_corte"], "datos": "sintéticos"}


@app.get("/predicciones")
def predicciones():
    """Catálogo de oraciones: la app construye cada pregunta y sus controles solo con esto."""
    return {"predicciones": CATALOGO}


@app.post("/predecir/{id_pred}")
def predecir(id_pred: str, peticion: Peticion):
    if id_pred not in {p["id"] for p in CATALOGO}:
        return _error(404, f"No existe la predicción '{id_pred}'.")
    salida = motor.predecir(id_pred, peticion.valores)
    respuesta = salida["respuesta"]
    _PREDICCIONES[respuesta["id_prediccion"]] = salida["graficas"]
    while len(_PREDICCIONES) > _MAX_GUARDADAS:
        _PREDICCIONES.popitem(last=False)
    return respuesta


@app.get("/graficas/{id_prediccion}")
def graficas(id_prediccion: str):
    if id_prediccion not in _PREDICCIONES:
        return _error(404, "No se encontró esa predicción. Vuelve a predecir para generar sus gráficas.")
    return _PREDICCIONES[id_prediccion]
