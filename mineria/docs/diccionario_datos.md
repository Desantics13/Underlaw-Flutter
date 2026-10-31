# Diccionario de datos

## Tablas de origen (MySQL `underlaw_mineria`)

### `secciones`
| Columna | Tipo | Descripción |
|---|---|---|
| id | INT PK | Identificador. |
| nombre | VARCHAR(100) | Camisetas, Hoodies, Pantalones, Accesorios. |
| orden | INT | Orden de aparición en la tienda. |

### `catalogo_productos` (prendas)
| Columna | Tipo | Descripción |
|---|---|---|
| id | INT PK | Identificador de la prenda. |
| nombre_lanzamiento | VARCHAR(150) | Drop al que pertenece. |
| nombre_producto | VARCHAR(150) | Nombre comercial. |
| precio | DECIMAL(10,2) | Precio en COP. |
| estado | ENUM | `activo` o `suspendido`. |
| tallas | JSON | Stock por talla: `[{"talla":"M","cantidad":12}, …]`. |
| seccion_id | INT FK | Sección del catálogo. |

### `lanzamientos` (drops)
| Columna | Tipo | Descripción |
|---|---|---|
| id | INT PK | Identificador. |
| nombre_lanzamiento | VARCHAR(150) | Nombre del drop. |
| fecha_lanzamiento | DATETIME | Fecha y hora en **UTC** (Colombia = UTC-5). |
| estado | ENUM | `programado` o `lanzado`. |
| producto_id | INT FK | Prenda principal del drop. |

### `lanzamiento_inscritos`
| Columna | Tipo | Descripción |
|---|---|---|
| lanzamiento_id | INT FK | Drop al que se inscribió. |
| nombre, apellido, correo, telefono | VARCHAR | Datos del interesado (sintéticos). |
| notificado_at | DATETIME | Cuándo se le avisó del lanzamiento. |

### `producto` (**pedidos**)
| Columna | Tipo | Descripción |
|---|---|---|
| id | INT PK | Número de pedido. |
| nombre_cliente, apellido_cliente, correo_cliente, telefono_cliente | VARCHAR | Comprador. El **correo** identifica al cliente. |
| nombre_producto, talla | VARCHAR | Líneas del carrito separadas por coma (así lo guarda el sistema real). |
| precio_producto | DECIMAL | Total del pedido en COP. |
| fecha_compra | TIMESTAMP | Fecha y hora de la compra. |
| metodo_pago | VARCHAR | `CARD`, `PSE` o `NEQUI` (Wompi). |
| estado_pago | VARCHAR | `APPROVED`, `PENDING`, `DECLINED`, `VOIDED` o `ERROR`. Solo `APPROVED` cuenta como venta. |

### `pedido_items` (detalle del pedido)
| Columna | Tipo | Descripción |
|---|---|---|
| pedido_id | INT FK | Pedido (`producto.id`). |
| producto_id | INT FK | Prenda (`catalogo_productos.id`). |
| talla | VARCHAR(20) | S, M, L, XL o Única. |
| cantidad | INT | Unidades de esa línea. |

### `direccion`
| Columna | Tipo | Descripción |
|---|---|---|
| pedido_id | INT FK | Pedido. |
| pais, municipio, ciudad, direccion | VARCHAR | Destino del envío. |

## Variables derivadas (lo que ven los modelos)

### P1 · Demanda semanal (`entrenamiento_p1_demanda_semanal.csv`)
| Variable | Cálculo |
|---|---|
| unidades (objetivo) | Suma de `cantidad` por semana (lunes a domingo) y alcance (total o sección). |
| lag_1 … lag_4 | Unidades de 1 a 4 semanas atrás. |
| media_movil_4 | Promedio de las 4 semanas anteriores (nivel reciente). |
| semana_sin, semana_cos | Semana del año en forma circular (estacionalidad). |
| temporada_alta | 1 desde el 15 de noviembre hasta el fin de diciembre. |
| black_friday, diciembre, inicio_anio | Indicadores de fechas comerciales. |
| drop_semana, drop_semana_anterior | 1 si hubo drop esa semana o la anterior. |
| semanas_desde_drop | Semanas desde el último drop. |
| efecto_drop | Efecto decreciente de los drops recientes: promedio diario de Σ exp(−días/7) para drops de los últimos 42 días. |
| tendencia | Semanas desde el inicio (crecimiento de la marca). |

Los modelos predicen el **cambio relativo** frente a `media_movil_4` (`log(unidades+1) − log(media_movil_4+1)`). Así los árboles no quedan limitados al rango histórico cuando la marca crece. El pronóstico es recursivo: cada semana predicha alimenta los lags de la siguiente.

### P2 · Recompra (`entrenamiento_p2_recompra.csv`)
Una fila por cliente y corte mensual, usando solo lo que se sabía a esa fecha.

| Variable | Cálculo |
|---|---|
| recencia_dias | Días entre la última compra y el corte. |
| frecuencia | Número de pedidos aprobados hasta el corte. |
| ticket_promedio | Gasto promedio por pedido (COP). |
| monto_total | Gasto acumulado (COP). |
| antiguedad_dias | Días desde la primera compra. |
| metodo_pago | Método más usado (categórica, one-hot). |
| recompra (objetivo) | 1 si compró de nuevo en los 60 días siguientes al corte. |

### P3 · Segmentos (`entrenamiento_p3_clientes.csv`)
Una fila por cliente con al menos un pedido aprobado hasta la fecha de corte (690 clientes).

| Variable | Cálculo |
|---|---|
| frecuencia_anual | Pedidos por año de vida como cliente (log). |
| ticket_promedio | Gasto promedio por pedido (log). |
| recencia_dias | Días desde la última compra al corte (log). |

Las tres variables se estandarizan antes de agrupar. `unidades_por_pedido` y `gasto_total` se usan solo para describir los segmentos, no para formarlos.
