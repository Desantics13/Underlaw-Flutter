# Resultados y comparación de modelos

> Generado automáticamente por `underlaw_ml/entrenar.py` el 2026-10-31 12:09 con datos leídos desde **MYSQL**. Datos **sintéticos** (ver `datos_sinteticos.md`).
> No editar a mano: se reescribe en cada entrenamiento.

## P1 · Regresión: unidades vendidas por semana
Validación temporal: 16 semanas finales como prueba; selección del ganador por RMSE promedio en validación cruzada temporal (TimeSeriesSplit, 5 pliegues) sobre el entrenamiento.

### Alcance: todas — ganador **Random Forest**

| Modelo | CV_RMSE | MAE | RMSE | MAPE_% | R2 |
|---|---|---|---|---|---|
| Regresión lineal | 66.357 | 42.836 | 51.218 | 18.41 | 0.3066 |
| Random Forest | 37.55 | 29.789 | 34.675 | 13.48 | 0.6822 |
| Gradient Boosting | 38.64 | 34.151 | 46.411 | 17.15 | 0.4307 |


### Alcance: Camisetas — ganador **Random Forest**

| Modelo | CV_RMSE | MAE | RMSE | MAPE_% | R2 |
|---|---|---|---|---|---|
| Regresión lineal | 84.365 | 34.403 | 41.311 | 25.2 | -0.1706 |
| Random Forest | 23.6 | 21.184 | 27.047 | 16.0 | 0.4982 |
| Gradient Boosting | 24.515 | 32.745 | 41.986 | 26.78 | -0.2092 |


### Alcance: Hoodies — ganador **Random Forest**

| Modelo | CV_RMSE | MAE | RMSE | MAPE_% | R2 |
|---|---|---|---|---|---|
| Regresión lineal | 11.683 | 11.53 | 16.772 | 25.99 | -0.0718 |
| Random Forest | 7.87 | 11.466 | 14.853 | 28.69 | 0.1594 |
| Gradient Boosting | 8.713 | 11.444 | 15.371 | 28.21 | 0.0998 |


### Alcance: Pantalones — ganador **Random Forest**

| Modelo | CV_RMSE | MAE | RMSE | MAPE_% | R2 |
|---|---|---|---|---|---|
| Regresión lineal | 25.585 | 4.122 | 5.125 | 22.27 | -0.1484 |
| Random Forest | 5.9 | 4.112 | 5.296 | 19.93 | -0.226 |
| Gradient Boosting | 6.542 | 5.718 | 7.035 | 28.84 | -1.1634 |


### Alcance: Accesorios — ganador **Gradient Boosting**

| Modelo | CV_RMSE | MAE | RMSE | MAPE_% | R2 |
|---|---|---|---|---|---|
| Regresión lineal | 14.064 | 9.147 | 11.693 | 28.36 | 0.4712 |
| Random Forest | 11.857 | 7.328 | 9.691 | 25.29 | 0.6368 |
| Gradient Boosting | 11.476 | 6.196 | 8.802 | 24.79 | 0.7004 |


## P2 · Clasificación: ¿volverá a comprar en 60 días?
Partición temporal: cortes mensuales; prueba desde 2026-02-01. Filas: 1931 entrenamiento / 3215 prueba. Tasa de recompra: 0.4878 (entrenamiento) / 0.4193 (prueba). Selección por ROC-AUC promedio en validación cruzada estratificada (5 pliegues).

Ganador: **Random Forest**

| Modelo | CV_ROC_AUC | ROC_AUC | accuracy | precision | recall | F1 |
|---|---|---|---|---|---|---|
| Regresión logística | 0.714 | 0.7753 | 0.7185 | 0.6518 | 0.7055 | 0.6776 |
| Random Forest | 0.7361 | 0.7756 | 0.7266 | 0.6759 | 0.6684 | 0.6721 |
| Red neuronal (MLP) | 0.7072 | 0.7812 | 0.7238 | 0.6627 | 0.6951 | 0.6785 |


Importancia de variables (permutación sobre prueba, caída del ROC-AUC):

| Variable | Importancia | Desviación |
|---|---|---|
| recencia_dias | 0.0616 | 0.0067 |
| monto_total | 0.0395 | 0.0033 |
| antiguedad_dias | 0.0277 | 0.0016 |
| frecuencia | 0.0122 | 0.0025 |
| ticket_promedio | 0.0045 | 0.0026 |
| metodo_pago | 0.0019 | 0.0013 |

## P3 · Clustering: segmentos de clientes
k elegido: **3** (mejor silueta entre 3 y 5). Clientes: 690. Ganador por silueta: **K-means**.

| Modelo | silueta | davies_bouldin | calinski_harabasz |
|---|---|---|---|
| K-means | 0.3407 | 1.057 | 461.9 |
| Mezcla gaussiana (GMM) | 0.1889 | 1.9453 | 206.93 |
| Jerárquico (Ward) | 0.3321 | 1.0394 | 397.02 |


Curva del codo y silueta (K-means):

| k | Inercia | Silueta |
|---|---|---|
| 2 | 1174.09 | 0.373 |
| 3 | 882.84 | 0.3407 |
| 4 | 709.47 | 0.3002 |
| 5 | 623.17 | 0.2958 |
| 6 | 558.42 | 0.2809 |
| 7 | 500.98 | 0.2709 |
| 8 | 449.07 | 0.2735 |

Perfil de cada segmento:

| Segmento | Clientes | Compras/año | Ticket promedio | Recencia (días) | Unidades/pedido | Gasto total |
|---|---|---|---|---|---|---|
| Ocasionales | 142 | 3.71 | 156955.0 | 146.5 | 1.44 | 364648.0 |
| En riesgo | 262 | 3.52 | 364854.0 | 194.5 | 2.87 | 1144218.0 |
| Premium | 286 | 13.42 | 389726.0 | 25.2 | 2.92 | 3459668.0 |
