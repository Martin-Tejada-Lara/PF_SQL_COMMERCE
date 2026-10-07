-- =====================================================================
-- Proyecto Capstone: Análisis de Ventas Retail (PostgreSQL)
-- =====================================================================
-- 0. Base de datos
-- ---------------------------------------------------------------------
-- CREATE DATABASE no puede ejecutarse dentro de la propia base que se crea,
-- por eso se corre una sola vez conectado a "postgres", y luego se cambia
-- la conexión a capstone_project antes de ejecutar el resto del script.
--
--   CREATE DATABASE capstone_project;
-- ---------------------------------------------------------------------
-- 1. Limpieza previa (permite re-ejecutar el script sin errores)
-- ---------------------------------------------------------------------
-- Se borra en orden inverso a las dependencias: transacciones referencia
-- a clientes y productos, así que debe eliminarse primero.
DROP TABLE IF EXISTS transacciones;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS clientes;
-- ---------------------------------------------------------------------
-- 2. Tabla clientes
-- ---------------------------------------------------------------------
CREATE TABLE clientes (
    -- Los IDs del dataset son alfanuméricos (ej: C0001), por eso VARCHAR y no INTEGER.
    customer_id   VARCHAR(10)  PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    region        VARCHAR(50),
    -- DATE alcanza: de la fecha de alta solo nos interesa el día, no la hora.
    signup_date   DATE
);
-- ---------------------------------------------------------------------
-- 3. Tabla productos
-- ---------------------------------------------------------------------
CREATE TABLE productos (
    product_id   VARCHAR(10)  PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    category     VARCHAR(50),
    -- NUMERIC (y no FLOAT) para dinero: evita errores de redondeo binario
    -- que harían fallar la validación total_value = quantity * price.
    price        NUMERIC(10,2) CHECK (price >= 0)
);
-- ---------------------------------------------------------------------
-- 4. Tabla transacciones (tabla central: une clientes y productos)
-- ---------------------------------------------------------------------
CREATE TABLE transacciones (
    transaction_id   VARCHAR(10) PRIMARY KEY,
    customer_id      VARCHAR(10) NOT NULL REFERENCES clientes(customer_id),
    product_id       VARCHAR(10) NOT NULL REFERENCES productos(product_id),
    -- Se guarda como TIMESTAMP porque el CSV trae fecha y hora.
    -- En el análisis se agrupa por mes con DATE_TRUNC y se castea a DATE.
    transaction_date TIMESTAMP,
    quantity         INTEGER CHECK (quantity > 0),
    -- total_value y price se dejan sin NOT NULL a propósito: el análisis usa
    -- COALESCE(total_value, quantity * price) para reconstruir el importe si
    -- llegara un valor vacío en una carga futura.
    total_value      NUMERIC(10,2) CHECK (total_value >= 0),
    price            NUMERIC(10,2) CHECK (price >= 0)
);
-- ---------------------------------------------------------------------
-- 5. Índices
-- ---------------------------------------------------------------------
-- Postgres indexa automáticamente las claves primarias, pero NO las foráneas.
-- Se indexan solo las columnas que usamos en JOIN y en GROUP BY por fecha;
-- indexar todo ralentizaría la carga sin mejorar las consultas.
CREATE INDEX idx_transacciones_customer ON transacciones(customer_id);
CREATE INDEX idx_transacciones_product  ON transacciones(product_id);
CREATE INDEX idx_transacciones_date     ON transacciones(transaction_date);
-- ---------------------------------------------------------------------
-- 6. Carga de datos (instrucciones)
-- ---------------------------------------------------------------------
-- Los datos NO están insertados en este script: se importan desde 3 CSV.
-- Respetar este orden, porque transacciones depende de las otras dos tablas.
--
-- Opción A - pgAdmin 4:
--   Clic derecho sobre la tabla > Import/Export Data
--   Formato: csv | Encoding: UTF8 | Header: activado | Delimitador: ,
--
-- Opción B - psql (ajustar la ruta a donde estén los archivos):
--   \copy clientes       FROM 'data/clientes.csv'       WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
--   \copy productos      FROM 'data/productos.csv'      WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
--   \copy transacciones  FROM 'data/transacciones.csv'  WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
--
-- El orden de columnas de cada CSV coincide con el de las tablas de arriba:
--   clientes:      CustomerID, CustomerName, Region, SignupDate
--   productos:     ProductID, ProductName, Category, Price
--   transacciones: TransactionID, CustomerID, ProductID, TransactionDate,
--                  Quantity, TotalValue, Price
-- ---------------------------------------------------------------------
-- 7. Verificación posterior a la carga
-- ---------------------------------------------------------------------
-- Confirma que la carga trajo filas en las tres tablas.
SELECT 'clientes' AS tabla, COUNT(*) AS filas FROM clientes
UNION ALL
SELECT 'productos', COUNT(*) FROM productos
UNION ALL
SELECT 'transacciones', COUNT(*) FROM transacciones;

-- Evidencia que los tipos de datos quedaron como se diseñaron (DATE, NUMERIC, etc.),
-- que es parte de la etapa de limpieza exigida antes del análisis.
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('clientes', 'productos', 'transacciones')
ORDER BY table_name, ordinal_position;
