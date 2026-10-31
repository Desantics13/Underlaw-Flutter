# UnderLaw · Minería de datos y predicciones

Este módulo Python le da a la app Flutter la sección **Insights**:
- **Minería y predicciones:** tres preguntas en forma de oración editable con el botón PREDECIR.
- **Gráficas:** cada gráfica conserva la referencia de la predicción que la originó.

Todo corre en local: **no toca** la base de producción (Railway), el backend Node ni la web.

```
MySQL local (underlaw_mineria)  ──►  Python (scikit-learn)  ──►  FastAPI :8000  ──►  App Flutter
       sql/*.sql                     underlaw_ml/entrenar.py     service/app.py      Insights
```

| Pregunta | Tipo | Modelos comparados | Ganador |
|---|---|---|---|
| Demanda de las próximas semanas | Regresión (serie de tiempo) | Lineal · Random Forest · Gradient Boosting | Random Forest |
| Probabilidad de recompra en 60 días | Clasificación binaria | Logística · Random Forest · Red neuronal | Random Forest |
| Segmento del cliente | Clustering | K-means · GMM · Jerárquico (Ward) | K-means (k = 3) |

## Documentación

| Archivo | Contenido |
|---|---|
| [docs/definicion_problema.md](docs/definicion_problema.md) | Preguntas de negocio, alcance y criterios de éxito. |
| [docs/modelo_entidad_relacion.md](docs/modelo_entidad_relacion.md) | Diagrama ER (Mermaid) y vista de minería. |
| [docs/diccionario_datos.md](docs/diccionario_datos.md) | Tablas, columnas y variables derivadas. |
| [docs/datos_sinteticos.md](docs/datos_sinteticos.md) | Cómo y por qué se generaron los datos. |
| [docs/justificacion_modelos.md](docs/justificacion_modelos.md) | Modelo base contra avanzados, validación y decisiones. |
| [docs/resultados_metricas.md](docs/resultados_metricas.md) | Métricas reales, generadas al entrenar. |
| [docs/contrato_api.md](docs/contrato_api.md) | Endpoints, JSON, códigos HTTP y gráficas. |
| [docs/ejemplos_json/](docs/ejemplos_json/) | Respuestas reales capturadas del servicio. |

## Puesta en marcha (Windows, PowerShell)

Todos los comandos se corren desde la carpeta `mineria/`.

### 1. Entorno de Python (una sola vez)
```powershell
cd mineria
py -3.13 -m venv venv
venv\Scripts\python -m pip install -r requirements.txt
```

### 2. Base de datos local (MySQL Workbench)

Los scripts **no contienen contraseñas**: las pones tú.

1. *(Opcional, recomendado)* Abre `sql/00_usuario.sql`, cambia `ESCRIBE_AQUI_TU_CLAVE` por una clave tuya y ejecútalo conectado como root. Crea el usuario `underlaw_ml`, con permisos solo sobre `underlaw_mineria`.
2. Ejecuta `sql/01_esquema.sql`. Crea la base, las tablas y la vista `v_mineria_items`.
3. Ejecuta `sql/02_datos.sql`. Carga los datos sintéticos (unos 1,8 MB; tarda unos segundos).

Comprobación rápida en Workbench:
```sql
SELECT estado_pago, COUNT(*) FROM underlaw_mineria.producto GROUP BY estado_pago;
-- APPROVED debe dar 3727
```

### 3. Archivo `.env`
```powershell
copy .env.example .env
notepad .env
```
Llena `DB_USER` y `DB_PASSWORD` con tu usuario de MySQL. `.env` está en `.gitignore`: nunca se sube.

### 4. Entrenar los modelos
```powershell
venv\Scripts\python -m underlaw_ml.entrenar mysql
```
- El argumento puede ser `mysql`, `csv` o vacío. Vacío usa `FUENTE_DATOS` del `.env`; `auto` intenta MySQL y, si no conecta, usa los CSV de `data/export/`.
- Genera `models/underlaw_modelos.joblib`, `models/metricas.json`, los CSV de entrenamiento y `docs/resultados_metricas.md`.
- Con la misma semilla, el resultado es idéntico desde MySQL o desde CSV.

### 5. Levantar el servicio de predicción
```powershell
venv\Scripts\uvicorn service.app:app --host 0.0.0.0 --port 8000
```
- Comprueba: http://localhost:8000/health
- Documentación interactiva: http://localhost:8000/docs

### 6. Pruebas
```powershell
venv\Scripts\python -m pytest -q
```

### 7. Correr la app contra el servicio

Desde la raíz del repo (`underlaw_flutter/`):

| Dónde corre la app | Comando |
|---|---|
| Navegador (Chrome) | `flutter run -d chrome` (en debug usa `http://localhost:8000` sola) |
| Emulador Android | `flutter run` (en debug usa `http://10.0.2.2:8000` solo) |
| Celular físico en la misma Wi-Fi | `flutter run --dart-define=ML_API_URL=http://<IP-del-PC>:8000` |
| APK de release | `flutter build apk --dart-define=ML_API_URL=http://<IP-o-URL>:8000` |

- Si un APK de release se compila **sin** `ML_API_URL`, la sección Insights muestra «Servicio no disponible» en vez de fallar.
- La IP del PC se ve con `ipconfig` (Adaptador Wi-Fi, «Dirección IPv4»).
- La primera vez, Windows pide permitir Python en el firewall: acepta para **redes privadas**.

## Regenerar los datos sintéticos

Solo si cambias el generador:
```powershell
venv\Scripts\python -m underlaw_ml.generar_datos
```
Reescribe:
- `data/export/*.csv`;
- `data/export/evidencia.xlsx`;
- `sql/02_datos.sql`.

Después vuelve a ejecutar `01_esquema.sql` y `02_datos.sql`, y entrena de nuevo.

## Estructura
```
mineria/
├── sql/              00_usuario.sql · 01_esquema.sql · 02_datos.sql
├── underlaw_ml/      config · generar_datos · datos · caracteristicas · entrenar · prediccion
├── service/app.py    API FastAPI
├── tests/            pruebas del servicio (pytest)
├── data/export/      CSV + evidencia.xlsx (tablas y datasets de entrenamiento)
├── models/           metricas.json (el .joblib se regenera al entrenar)
└── docs/             documentación
```

## Licencias de las librerías de gráficas (app)

- **fl_chart** y **graphic**: MIT.
- **Syncfusion Flutter Charts / Gauges**: licencia comercial con **Community License** gratuita para estudiantes, personas e ingresos pequeños. Para un proyecto académico aplica la Community License.
