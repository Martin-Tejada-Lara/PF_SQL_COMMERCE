CONSULTA COMPLETA
SE IMPORTARON LAS TABLAS DESDE 3 ARCHIVOS CVS (ADJUNTADOS EN EL DRIVE)
LAS TABLAS SON: PRODUCTOS, CLIENTES Y TRANSACCIONES (ventas)


SELECT 'clientes' AS tabla, COUNT(*) AS filas FROM clientes
UNION ALL
SELECT 'productos', COUNT(*) FROM productos
UNION ALL
SELECT 'transacciones', COUNT(*) FROM transacciones;

--nulos en transactions
SELECT
    COUNT(*)                                            AS total_filas,
    COUNT(*) FILTER (WHERE transaction_date IS NULL)    AS fechas_nulas,
    COUNT(*) FILTER (WHERE total_value IS NULL)         AS total_nulo,
    COUNT(*) FILTER (WHERE price IS NULL)               AS precio_nulo,
    COUNT(*) FILTER (WHERE quantity IS NULL)            AS cantidad_nula
FROM transacciones;

--nulos en clientes

SELECT
    COUNT(*)                                      AS total_filas,
    COUNT(*) FILTER (WHERE region IS NULL)        AS region_nula,
    COUNT(*) FILTER (WHERE signup_date IS NULL)   AS fecha_alta_nula
FROM clientes;

--nulos en productos
SELECT
    COUNT(*)                                     AS total_filas,
    COUNT(*) FILTER (WHERE price IS NULL)        AS precio_nulo,
    COUNT(*) FILTER (WHERE category IS NULL)     AS categoria_nula,
    COUNT(*) FILTER (WHERE product_name IS NULL) AS nombre_nulo
FROM productos;

--p x q
SELECT COUNT(*) AS filas_inconsistentes
FROM transacciones
WHERE total_value <> quantity * price;

--valores raros o invalidos
SELECT COUNT(*) AS valores_invalidos
FROM transacciones
WHERE quantity <= 0 OR price <= 0 OR total_value <= 0;

SELECT
    c.customer_id,
    c.customer_name,
    c.region,
    SUM(COALESCE(t.total_value, t.quantity * t.price)) AS gasto_total,
    COUNT(*)                                           AS cantidad_compras
FROM transacciones t
JOIN clientes c ON c.customer_id = t.customer_id
GROUP BY c.customer_id, c.customer_name, c.region
ORDER BY gasto_total DESC
LIMIT 5;

--estacionalidad: meses fuertes y débiles para planificar campañas y stock.
SELECT
    DATE_TRUNC('month', transaction_date)::DATE        AS mes,
    SUM(COALESCE(total_value, quantity * price))       AS ventas_totales,
    COUNT(*)                                           AS cantidad_transacciones
FROM transacciones
GROUP BY 1
ORDER BY 1;

--Detectamos productos de baja rotación para evaluar descuentos o descontinuarlos
SELECT
    p.product_id,
    p.product_name,
    p.category,
    COALESCE(SUM(t.quantity), 0) AS unidades_vendidas
FROM productos p
LEFT JOIN transacciones t ON t.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY unidades_vendidas ASC
LIMIT 3;

--los 3 pedidos mas grandes dentro de cada categoria,
-- porque comparar pedidos de categorías distintas (libros vs. electrónica) no sería justo.
WITH pedidos_ranking AS (
    SELECT
        t.transaction_id,
        p.category,
        t.total_value,
        RANK() OVER (PARTITION BY p.category ORDER BY t.total_value DESC) AS ranking
    FROM transacciones t
    JOIN productos p ON p.product_id = t.product_id
)
SELECT *
FROM pedidos_ranking
WHERE ranking <= 3
ORDER BY category, ranking;

-- Verificamos empates en el tercer puesto, porque LIMIT 3 corta de forma arbitraria.
SELECT p.product_id, p.product_name, COALESCE(SUM(t.quantity), 0) AS unidades_vendidas
FROM productos p
LEFT JOIN transacciones t ON t.product_id = p.product_id
GROUP BY p.product_id, p.product_name
HAVING COALESCE(SUM(t.quantity), 0) <= 12
ORDER BY unidades_vendidas, p.product_id;
