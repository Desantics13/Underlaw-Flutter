# Definición del problema

## Contexto

UnderLaw es una marca de ropa de Cartagena que vende por drops: lanzamientos de edición limitada anunciados con fecha y hora. La tienda tiene web (underlaw.site), app móvil en Flutter y un backend Node + MySQL que registra los pedidos pagados con Wompi.

Hoy las decisiones se toman a ojo:
- cuánto producir para el próximo drop;
- a qué clientes escribirles;
- cómo tratar a cada tipo de comprador.

La minería de datos convierte el historial de pedidos en respuestas concretas que la app muestra al equipo.

## Preguntas de negocio

| # | Pregunta | Tipo de problema | Para qué sirve |
|---|---|---|---|
| P1 | ¿Cuántas unidades se venderán en las próximas *n* semanas (por sección y con o sin el drop programado)? | Regresión sobre serie de tiempo semanal | Planear producción e inventario del siguiente drop. |
| P2 | ¿Un cliente con cierto historial volverá a comprar en los próximos 60 días? | Clasificación binaria | Decidir a quién enviar campañas de recompra antes de que se pierda. |
| P3 | ¿A qué segmento pertenece un cliente según su frecuencia, ticket y recencia? | Clustering (aprendizaje no supervisado) | Dar un trato distinto a Premium, Ocasionales y En riesgo. |

## Alcance

- **Datos:** base MySQL **local** `underlaw_mineria`, con la misma estructura de la base real (ver `modelo_entidad_relacion.md`). Los datos son **sintéticos** (ver `datos_sinteticos.md`), porque la tienda real aún no tiene volumen suficiente para entrenar.
- **Producción intacta:** no se toca la base de producción (Railway), ni el backend Node, ni la web.
- **Modelos:** Python (scikit-learn). Para cada pregunta se comparan al menos tres algoritmos, uno base y otros más avanzados, con métricas en datos que el modelo no vio (ver `justificacion_modelos.md` y `resultados_metricas.md`).
- **Consumo:** un microservicio FastAPI (`service/app.py`) expone las predicciones como JSON. La app Flutter muestra cada pregunta como una oración editable con el botón **PREDECIR** y sus gráficas en la sección **Gráficas** (ver `contrato_api.md`).

## Criterios de éxito

| Pregunta | Métrica principal | Umbral razonable | Resultado obtenido |
|---|---|---|---|
| P1 | RMSE / MAPE en 16 semanas de prueba | MAPE < 20 % en el total | RF: MAPE 13,5 %, R² 0,68 |
| P2 | ROC-AUC en prueba temporal | > 0,70 | RF: 0,776 |
| P3 | Coeficiente de silueta | > 0,25 | K-means k = 3: 0,341 |

## Limitaciones

- Los datos sintéticos siguen reglas plausibles (estacionalidad, drops, segmentos), pero no reemplazan ventas reales. Cuando la tienda acumule historial, basta con apuntar el entrenamiento a esos datos: el código no cambia.
- Las secciones con poco volumen (Hoodies, Pantalones) tienen predicciones débiles (R² bajo o negativo). La app muestra la métrica para que esto quede a la vista.
