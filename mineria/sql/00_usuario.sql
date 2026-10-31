-- =============================================================================
-- (Opcional, recomendado) Usuario de MySQL SOLO para este proyecto.
-- Así los scripts de Python no usan "root" y solo pueden tocar underlaw_mineria.
--
-- 1. Cambia 'ESCRIBE_AQUI_TU_CLAVE' por una contraseña tuya.
-- 2. Corre este archivo en MySQL Workbench conectado como root.
-- 3. Pon el mismo usuario y clave en el archivo .env (DB_USER / DB_PASSWORD).
-- La contraseña nunca va en el código ni se sube a GitHub (.env está en .gitignore).
-- =============================================================================
CREATE DATABASE IF NOT EXISTS underlaw_mineria
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'underlaw_ml'@'localhost' IDENTIFIED BY 'ESCRIBE_AQUI_TU_CLAVE';
GRANT ALL PRIVILEGES ON underlaw_mineria.* TO 'underlaw_ml'@'localhost';
FLUSH PRIVILEGES;
