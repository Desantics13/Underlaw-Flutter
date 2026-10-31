# Contrato de la API de predicción

Microservicio FastAPI en `service/app.py`. Es **independiente** del backend Node de la tienda: no toca la base de producción ni la web. La app Flutter lo consume desde `lib/features/insights/data/ml_api.dart`.

- Base local: `http://localhost:8000` (Android emulador: `http://10.0.2.2:8000`).
- Documentación interactiva (Swagger): `http://localhost:8000/docs`.
- Todas las respuestas son JSON en UTF-8.
- Ejemplos reales capturados del servicio: carpeta `docs/ejemplos_json/`.

## Endpoints

| Método | Ruta | Para qué | Códigos |
|---|---|---|---|
| GET | `/health` | Estado del servicio y de los modelos. | 200 |
| GET | `/predicciones` | Catálogo de oraciones: la app arma cada pregunta y sus controles solo con esto. | 200 |
| POST | `/predecir/{id}` | Ejecuta una predicción con los valores elegidos. `id` = `demanda`, `recompra` o `segmento`. | 200, 400, 404, 500 |
| GET | `/graficas/{id_prediccion}` | Datos de las gráficas de esa predicción, con su referencia. | 200, 404 |

### GET /health
```json
{"estado": "ok", "modelos_entrenados": "2026-10-28 17:22", "fuente_entrenamiento": "csv",
 "fecha_corte_datos": "2026-09-30", "datos": "sintéticos"}
```

### GET /predicciones
Ejemplo completo: `predicciones.json`. Cada predicción trae:
- `plantilla`: la oración, con los campos entre llaves;
- `campos`: tipo `opcion`, `entero` o `dinero`, con sus límites, paso, valor por defecto y formato singular/plural.

```json
{"id": "recompra", "titulo": "Probabilidad de recompra", "tipo_problema": "Clasificación binaria",
 "plantilla": "¿Un cliente con {frecuencia}, ticket promedio de {ticket_promedio}, ...?",
 "campos": [{"id": "frecuencia", "tipo": "entero", "min": 1, "max": 40, "paso": 1, "defecto": 3,
             "formato": {"singular": "1 compra", "plural": "{n} compras"}}, "..."]}
```

### POST /predecir/{id}
Petición:
```json
{"valores": {"frecuencia": 3, "ticket_promedio": 250000, "recencia_dias": 30,
             "antiguedad_dias": 240, "metodo_pago": "CARD"}}
```
Los campos que no se envían toman su valor por defecto.

Respuesta 200 (resumida; completa en `predecir_recompra.json`):
```json
{"id_prediccion": "d21939da8c98", "prediccion": "recompra",
 "pregunta": "¿Un cliente con 3 compras, ticket promedio de $250.000, ...?",
 "resultado": {"valor": 0.477, "texto": "No volvería a comprar · 48 %", "detalle": "..."},
 "probabilidad": 0.477, "clase": "no_recompra",
 "modelo": {"nombre": "Random Forest",
            "comparados": ["Regresión logística", "Random Forest", "Red neuronal (MLP)"],
            "criterio": "Mayor ROC-AUC en validación cruzada"},
 "metricas": {"CV_ROC_AUC": 0.7361, "ROC_AUC": 0.7756, "F1": 0.6721},
 "explicacion": "Según Random Forest, la probabilidad es 48 %. ...",
 "datos": {"origen": "sintéticos", "fecha_corte": "2026-09-30"}}
```

### GET /graficas/{id_prediccion}
```json
{"referencia": {"id_prediccion": "d21939da8c98", "titulo": "...", "pregunta": "...",
                "valores": {"...": "..."}, "resultado": "No volvería a comprar · 48 %"},
 "graficas": [{"id": "medidor", "tipo": "medidor", "titulo": "...", "descripcion": "...", "...": "datos"}]}
```

Las predicciones se guardan en memoria (las últimas 300). Si el servicio se reinicia, `/graficas/{id}` responde 404 y la app pide volver a predecir.

| `tipo` | Predicción | Widget en Flutter | Librería |
|---|---|---|---|
| `serie_proyeccion` | demanda | `SerieProyeccion` | Syncfusion Charts |
| `real_vs_predicho` | demanda | `RealVsPredicho` | Syncfusion Charts |
| `barras_metricas` | demanda y segmento | `BarrasMetricas` | fl_chart |
| `mapa_calor` | demanda | `MapaCalor` | graphic |
| `medidor` | recompra | `Medidor` | Syncfusion Gauges |
| `barras_probabilidad` | recompra | `BarrasProbabilidad` | Flutter (propia) |
| `curva_sensibilidad` | recompra | `CurvaSensibilidad` | Syncfusion Charts |
| `curva_roc` | recompra | `CurvaRoc` | Syncfusion Charts |
| `matriz_confusion` | recompra | `MatrizConfusion` | graphic |
| `importancia_variables` | recompra | `ImportanciaVariables` | Flutter (propia) |
| `dispersion_clusters` | segmento | `DispersionClusters` | Syncfusion Charts |
| `radar_segmentos` | segmento | `RadarSegmentos` | fl_chart |
| `codo_silueta` | segmento | `CodoSilueta` | Syncfusion Charts |

## Errores

Todos los errores tienen la misma forma:

| Código | Cuándo | Ejemplo |
|---|---|---|
| 400 | Valor fuera de rango, opción inexistente o cuerpo mal formado. | `{"error": "'semanas' debe estar entre 1 y 12", "codigo": 400}` |
| 404 | Predicción o `id_prediccion` inexistente. | `{"error": "No existe la predicción 'xyz'.", "codigo": 404}` |
| 500 | Error inesperado; el detalle queda en el log del servicio, no en la respuesta. | `{"error": "Error interno del servidor.", "codigo": 500}` |

## CORS

Se permiten:
- los orígenes de la variable `CORS_ORIGENES` del archivo `.env`;
- cualquier `localhost` o `127.0.0.1`, para Flutter web en desarrollo.

La app Android no necesita CORS.
