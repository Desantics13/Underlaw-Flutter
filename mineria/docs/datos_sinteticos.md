# Datos sintéticos

## Por qué

La tienda real tiene muy pocos pedidos todavía, lo que no alcanza para entrenar ni para evaluar modelos con un conjunto de prueba. Por eso `underlaw_ml/generar_datos.py` simula **24 meses de operación** (2024-10-01 a 2026-09-30):
- con la misma estructura de tablas de la base real;
- con comportamientos plausibles para una marca de ropa en Colombia.

**Los datos no representan clientes ni ventas reales.** Nombres, correos, teléfonos y direcciones son inventados.

## Reproducibilidad

Todo sale de una semilla fija (`SEMILLA = 2026` en `config.py`): correr el generador de nuevo produce exactamente los mismos datos.

```powershell
venv\Scripts\python -m underlaw_ml.generar_datos
```

Salidas:
- `data/export/*.csv`: una tabla por archivo;
- `data/export/evidencia.xlsx`: las mismas tablas, una hoja por tabla;
- `sql/02_datos.sql`: INSERTs para MySQL Workbench.

## Volumen generado

| Elemento | Cantidad |
|---|---|
| Pedidos (`producto`) | 4.134 (3.727 aprobados) |
| Líneas de pedido (`pedido_items`) | 10.440 |
| Clientes con pedidos | 711 (de 900 simulados) |
| Prendas en catálogo | 31, en 4 secciones |
| Lanzamientos | 10 (9 pasados y 1 programado: «Drop Diciembre», 27-nov-2026) |
| Inscritos a lanzamientos | 160 |

## Reglas de la simulación

1. **Drops:** 9 lanzamientos entre oct-2024 y ago-2026. Cada uno sube las ventas hasta 2,6× el día del drop, y el efecto decae en unas 5 semanas (exp(−días/6)). Las prendas nuevas se eligen más al principio, y las de más de 300 días casi dejan de venderse.
2. **Estacionalidad:**
   - meses: diciembre ×1,6, noviembre ×1,25, enero ×0,75;
   - días: viernes y sábado ×1,2;
   - fechas comerciales: Black Friday, Día de la Madre, Día del Padre, Amor y Amistad, Navidad.
3. **Tendencia:** la marca crece; la demanda base pasa de 0,75 a 1,35 a lo largo de los dos años, y entran más clientes nuevos con el tiempo.
4. **Tres tipos de cliente**, ocultos: los modelos nunca ven esta etiqueta.

   | Tipo | Participación | Compras/año | Ítems por pedido | Abandono medio |
   |---|---|---|---|---|
   | Ocasional | 60 % | 2 | 1–3 | 220 días |
   | Frecuente | 28 % | 9 | 1–4 | 520 días |
   | Premium | 12 % | 6,5 | 2–5 | 650 días |

   Después de «abandonar», el cliente compra al 12 % de su ritmo, para que exista algo que predecir en recompra.
5. **Pagos:** CARD 45 %, PSE 33 %, NEQUI 22 %. Estados: 90 % aprobados, 5 % rechazados, 4 % anulados, 1 % error, y pendientes solo en los últimos 2 días.
6. **Geografía:** Cartagena 34 %, Bogotá 20 %, Barranquilla 14 %, Medellín 12 % y otras ciudades del Caribe y el Pacífico.
7. **Tallas:** M y L dominan, y cada cliente tiende a repetir su talla (85 %).

## Cómo se validó que los datos son útiles

- El clustering **redescubre** grupos parecidos a los tipos ocultos (Premium, Ocasionales, En riesgo) sin conocer la etiqueta.
- Los modelos de demanda superan claramente a la regresión lineal base, lo que indica patrones no lineales reales (drops y estacionalidad).
- La recompra depende sobre todo de la recencia, como en el comercio real.
