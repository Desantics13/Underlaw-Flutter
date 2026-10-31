-- =============================================================================
-- UnderLaw · Base LOCAL para minería de datos (underlaw_mineria)
-- -----------------------------------------------------------------------------
-- Es la MISMA estructura final de la base real (database.sql + migraciones del
-- proyecto web), ya consolidada: cada tabla con todas sus columnas actuales.
-- Se omiten solo las tablas de contenido del sitio (sitio_ajustes,
-- sitio_imagenes, sitio_videos) porque no aportan a la minería.
--
-- OJO: la tabla "producto" guarda los PEDIDOS (compras de clientes); el
-- catálogo de prendas está en "catalogo_productos". Se respeta el nombre real.
--
-- Cómo correrlo en MySQL Workbench: File > Open SQL Script > este archivo >
-- ejecutar todo (rayo). Luego 02_datos.sql. Es seguro correrlo dos veces.
-- NO se conecta a Railway ni toca la base de producción.
-- =============================================================================
CREATE DATABASE IF NOT EXISTS underlaw_mineria
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE underlaw_mineria;

CREATE TABLE IF NOT EXISTS secciones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    orden INT NOT NULL DEFAULT 0,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS catalogo_productos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre_lanzamiento VARCHAR(150) NOT NULL,
    nombre_producto VARCHAR(150) NOT NULL,
    precio DECIMAL(10, 2) NOT NULL,
    imagen VARCHAR(255),
    imagen_public_id VARCHAR(255),
    estado ENUM('activo', 'suspendido') NOT NULL DEFAULT 'activo',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    descripcion TEXT NULL,
    detalle VARCHAR(120) NULL,
    tallas JSON NULL,
    seccion_id INT NULL,
    CONSTRAINT fk_catalogo_producto_seccion
        FOREIGN KEY (seccion_id) REFERENCES secciones(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS catalogo_producto_imagenes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    catalogo_producto_id INT NOT NULL,
    imagen VARCHAR(255) NOT NULL,
    imagen_public_id VARCHAR(255),
    orden INT NOT NULL DEFAULT 0,
    CONSTRAINT fk_imagen_catalogo_producto
        FOREIGN KEY (catalogo_producto_id) REFERENCES catalogo_productos(id)
        ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS lanzamientos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre_lanzamiento VARCHAR(150) NOT NULL,
    nombre_producto    VARCHAR(150) NOT NULL,
    precio             DECIMAL(10, 2) NOT NULL,
    imagenes           JSON NOT NULL,
    fecha_lanzamiento  DATETIME NOT NULL,          -- en UTC (Colombia = UTC-5)
    activo_en_home     TINYINT(1) NOT NULL DEFAULT 0,
    estado             ENUM('programado', 'lanzado') NOT NULL DEFAULT 'programado',
    producto_id        INT NULL,
    created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    descripcion        TEXT NULL,
    detalle            VARCHAR(120) NULL,
    tallas             JSON NULL,
    seccion_id         INT NULL,
    INDEX idx_lanzamiento_pendiente (estado, fecha_lanzamiento),
    CONSTRAINT fk_lanzamiento_producto
        FOREIGN KEY (producto_id) REFERENCES catalogo_productos(id) ON DELETE SET NULL,
    CONSTRAINT fk_lanzamiento_seccion
        FOREIGN KEY (seccion_id) REFERENCES secciones(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS lanzamiento_inscritos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    lanzamiento_id INT NOT NULL,
    nombre    VARCHAR(100) NOT NULL,
    apellido  VARCHAR(100) NOT NULL,
    correo    VARCHAR(150) NOT NULL,
    telefono  VARCHAR(30)  NOT NULL,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notificado_at DATETIME NULL,
    CONSTRAINT fk_inscrito_lanzamiento
        FOREIGN KEY (lanzamiento_id) REFERENCES lanzamientos(id) ON DELETE CASCADE,
    UNIQUE KEY uq_inscrito_correo_lanzamiento (lanzamiento_id, correo)
);

-- "producto" = PEDIDOS. nombre_producto y talla guardan las líneas del carrito
-- separadas por coma (así funciona el sistema real); el detalle estructurado
-- está en pedido_items.
CREATE TABLE IF NOT EXISTS producto (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre_cliente VARCHAR(100) NOT NULL,
    apellido_cliente VARCHAR(100) NOT NULL,
    correo_cliente VARCHAR(150) NOT NULL,
    telefono_cliente VARCHAR(20) NOT NULL,
    nombre_producto VARCHAR(150) NOT NULL,
    precio_producto DECIMAL(10, 2) NOT NULL,
    fecha_compra TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metodo_pago VARCHAR(50) DEFAULT 'No especificado',
    referencia_pago VARCHAR(100) UNIQUE,
    estado_pago VARCHAR(20) DEFAULT 'PENDING',
    wompi_transaction_id VARCHAR(100),
    email_enviado TINYINT(1) DEFAULT 0,
    talla VARCHAR(100),
    inventario_descontado TINYINT(1) NOT NULL DEFAULT 0,
    INDEX idx_producto_fecha (fecha_compra),
    INDEX idx_producto_correo (correo_cliente)
);

CREATE TABLE IF NOT EXISTS direccion (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT NOT NULL,
    pais VARCHAR(100) NOT NULL,
    municipio VARCHAR(100) NOT NULL,
    ciudad VARCHAR(100) NOT NULL,
    direccion VARCHAR(255) NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_direccion_pedido
        FOREIGN KEY (pedido_id) REFERENCES producto(id) ON DELETE CASCADE,
    UNIQUE KEY uq_direccion_pedido (pedido_id)
);

CREATE TABLE IF NOT EXISTS pedido_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT NOT NULL,
    producto_id INT NULL,
    nombre_producto VARCHAR(150) NOT NULL,
    talla VARCHAR(20) NULL,
    cantidad INT NOT NULL,
    CONSTRAINT fk_pedido_item_pedido
        FOREIGN KEY (pedido_id) REFERENCES producto(id) ON DELETE CASCADE,
    CONSTRAINT fk_pedido_item_producto
        FOREIGN KEY (producto_id) REFERENCES catalogo_productos(id) ON DELETE SET NULL,
    INDEX idx_pedido_item_pedido (pedido_id)
);

CREATE TABLE IF NOT EXISTS notificaciones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    mensaje VARCHAR(255) NOT NULL,
    leida TINYINT(1) NOT NULL DEFAULT 0,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- Vista de minería: una fila por prenda vendida en pedidos APROBADOS, ya unida
-- con el cliente, la ciudad de envío, el precio y la sección del catálogo.
-- Es la base de las tres predicciones (demanda, recompra y segmentación).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_mineria_items AS
SELECT
    pi.id              AS item_id,
    p.id               AS pedido_id,
    p.fecha_compra,
    p.correo_cliente,
    p.metodo_pago,
    d.ciudad,
    pi.producto_id,
    cp.nombre_producto,
    cp.nombre_lanzamiento,
    s.nombre           AS seccion,
    pi.talla,
    pi.cantidad,
    cp.precio          AS precio_unitario,
    pi.cantidad * cp.precio AS subtotal
FROM pedido_items pi
JOIN producto p            ON p.id = pi.pedido_id
LEFT JOIN direccion d      ON d.pedido_id = p.id
LEFT JOIN catalogo_productos cp ON cp.id = pi.producto_id
LEFT JOIN secciones s      ON s.id = cp.seccion_id
WHERE p.estado_pago = 'APPROVED';
