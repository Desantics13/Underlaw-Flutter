# Justificación de los modelos

Para cada pregunta se compara un **modelo base**, simple e interpretable, con dos **modelos avanzados**. El ganador se elige con validación cruzada sobre el entrenamiento y después se reporta su desempeño en datos que **no vio**. Las cifras exactas están en `resultados_metricas.md` (generado al entrenar).

## P1 · Regresión: demanda semanal

| Modelo | Rol | Por qué |
|---|---|---|
| Regresión lineal | Base | Referencia mínima: si un modelo complejo no la supera, no vale la pena. |
| Random Forest | Avanzado | Capta interacciones no lineales (drop × temporada) y es robusto con pocas semanas. |
| Gradient Boosting | Avanzado | Corrige errores en secuencia; suele ser el más preciso en datos tabulares. |

**Validación:**
- Las 16 semanas finales son la prueba.
- El ganador se elige con `TimeSeriesSplit` de 5 pliegues, que nunca entrena con el futuro.
- Métrica de selección: RMSE en validación cruzada. También se reportan MAE, RMSE, MAPE y R² en prueba.

**Decisiones técnicas:**
- **Objetivo relativo:** los árboles no extrapolan, así que predecir unidades absolutas los dejaba por debajo de la tendencia. Por eso los tres modelos predicen el cambio frente a la media de las últimas 4 semanas (`ModeloRelativo`).
- **Pronóstico recursivo**, para varias semanas.
- **Intervalo de confianza:** σ·√h (80 % y 95 %), donde σ es el RMSE de prueba y h el horizonte.

**Resultado (total de prendas):**
- Random Forest gana: RMSE 34,7 frente a 51,2 de la lineal; R² 0,68; MAPE 13,5 %.
- En Accesorios gana Gradient Boosting.
- Hoodies y Pantalones venden poco y su R² es bajo. Se reporta tal cual.

## P2 · Clasificación: recompra en 60 días

| Modelo | Rol | Por qué |
|---|---|---|
| Regresión logística | Base | Interpretable: cada variable sube o baja la probabilidad. |
| Random Forest | Avanzado | Capta umbrales, por ejemplo «después de ~90 días la probabilidad cae». |
| Red neuronal (MLP) | Avanzado | Modelo flexible de referencia: 2 capas ocultas (32 y 16 neuronas) con early stopping. |

**Validación:**
- Partición **temporal**: los cortes mensuales anteriores a 2026-02-01 entrenan y los posteriores prueban. Así se evita la fuga de información.
- Selección por ROC-AUC en validación cruzada estratificada de 5 pliegues.
- En prueba se reportan ROC-AUC, exactitud, precisión, sensibilidad y F1, con la matriz de confusión al umbral de 50 %.

**Resultado:**
- Los tres quedan cerca en prueba (ROC-AUC entre 0,775 y 0,781).
- Gana Random Forest por validación cruzada (0,736).
- La variable más importante, por permutación, es `recencia_dias`; le siguen `monto_total` y `antiguedad_dias`.

## P3 · Clustering: segmentos de clientes

| Modelo | Rol | Por qué |
|---|---|---|
| K-means | Base | Rápido, con centroides fáciles de explicar. |
| Mezcla gaussiana (GMM) | Avanzado | Grupos elípticos y pertenencia probabilística. |
| Jerárquico (Ward) | Avanzado | No asume forma esférica; útil para confirmar la estructura. |

**Elección de k:** se buscó el k con mejor silueta entre 3 y 5. k = 2 tiene una silueta un poco mayor, pero dos grupos no sirven para el negocio. La curva del codo acompaña la decisión.

**Métricas:** silueta (mayor es mejor), Davies-Bouldin (menor es mejor) y Calinski-Harabasz (mayor es mejor).

**Nombres de los segmentos:** se asignan por rasgos, no por número de grupo.
- **Premium:** el grupo de mayor valor (frecuencia × ticket, castigado por la inactividad).
- **En riesgo:** entre los demás, el de más tiempo sin comprar.
- **Ocasionales:** entre los demás, el de menor ticket.

**Resultado:**
- K-means con k = 3: silueta 0,341 (GMM 0,189; Ward 0,332).
- Premium: 286 clientes, 13,4 compras al año, última compra hace 25 días en promedio.
- En riesgo: 262 clientes, ticket alto de $365.000, pero sin comprar hace 194 días.
- Ocasionales: 142 clientes.

## Cómo se usa en la app

Cada predicción se hace **en vivo**: la app envía los valores de la oración, el servicio aplica el modelo ganador y responde con el resultado, la explicación y las métricas del modelo. Las gráficas de esa predicción conservan su referencia (la pregunta, los valores y el ID).
