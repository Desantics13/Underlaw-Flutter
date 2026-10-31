# Modelo entidad-relación

Base local `underlaw_mineria`. Es la estructura final de la base real de la tienda (`database.sql` más las migraciones del proyecto web), consolidada en `sql/01_esquema.sql`.

Se omiten solo las tablas de contenido del sitio (`sitio_ajustes`, `sitio_imagenes`, `sitio_videos`), que no aportan a la minería.

> **Ojo:** la tabla `producto` guarda los **pedidos** (compras de clientes). El catálogo de prendas está en `catalogo_productos`. Se respeta el nombre real para no romper la compatibilidad.

```mermaid
erDiagram
    secciones ||--o{ catalogo_productos : "agrupa"
    secciones ||--o{ lanzamientos : "clasifica"
    catalogo_productos ||--o{ catalogo_producto_imagenes : "tiene"
    catalogo_productos ||--o{ lanzamientos : "se lanza en"
    catalogo_productos ||--o{ pedido_items : "se vende en"
    lanzamientos ||--o{ lanzamiento_inscritos : "avisa a"
    producto ||--o{ pedido_items : "contiene"
    producto ||--|| direccion : "se envía a"

    secciones {
        int id PK
        varchar nombre
        int orden
    }
    catalogo_productos {
        int id PK
        varchar nombre_lanzamiento
        varchar nombre_producto
        decimal precio
        enum estado
        json tallas
        int seccion_id FK
    }
    catalogo_producto_imagenes {
        int id PK
        int catalogo_producto_id FK
        varchar imagen
        int orden
    }
    lanzamientos {
        int id PK
        varchar nombre_lanzamiento
        datetime fecha_lanzamiento
        enum estado
        int producto_id FK
        int seccion_id FK
    }
    lanzamiento_inscritos {
        int id PK
        int lanzamiento_id FK
        varchar correo
        datetime notificado_at
    }
    producto {
        int id PK
        varchar correo_cliente
        decimal precio_producto
        timestamp fecha_compra
        varchar metodo_pago
        varchar estado_pago
    }
    pedido_items {
        int id PK
        int pedido_id FK
        int producto_id FK
        varchar talla
        int cantidad
    }
    direccion {
        int id PK
        int pedido_id FK
        varchar ciudad
        varchar municipio
    }
    notificaciones {
        int id PK
        varchar mensaje
        tinyint leida
    }
```

## Vista de minería `v_mineria_items`

Es la fuente de las tres predicciones: una fila por prenda vendida en pedidos **aprobados** (`estado_pago = 'APPROVED'`).

```
pedido_items ─┬─ producto (pedido) ── direccion
              └─ catalogo_productos ── secciones
```

Columnas:
- `item_id`, `pedido_id`, `fecha_compra`, `correo_cliente`, `metodo_pago`, `ciudad`;
- `producto_id`, `nombre_producto`, `nombre_lanzamiento`, `seccion`, `talla`, `cantidad`;
- `precio_unitario`, `subtotal`.

El cliente se identifica por `correo_cliente`, porque la base real no tiene una tabla de clientes.
