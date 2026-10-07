# PF_SQL_COMMERCE
Ventas de Comercio analisis en SQL
# Capstone Project - Análisis de Ventas Retail
## Descripción del proyecto
Este proyecto corresponde a un análisis de datos de ventas de una empresa del sector retail utilizando **PostgreSQL y SQL**.
El objetivo es trabajar con información de clientes, productos y transacciones para realizar un proceso básico de preparación, validación y análisis de datos, obteniendo información útil para la toma de decisiones comerciales.
El proyecto contempla desde la creación y validación de las estructuras de datos hasta la elaboración de consultas analíticas orientadas a identificar clientes de alto valor, evolución de ventas, productos de baja rotación y principales transacciones por categoría.

---

## Objetivo

Analizar el comportamiento de las ventas y obtener información relevante sobre clientes, productos y categorías mediante consultas SQL.
Los principales objetivos del análisis son:

* Identificar los clientes con mayor volumen de compras.
* Analizar la evolución mensual de las ventas.
* Detectar productos con menor cantidad de unidades vendidas.
* Identificar las transacciones de mayor valor dentro de cada categoría.
* Aplicar técnicas de SQL para agrupación, combinación, transformación y análisis de datos.

---

## Dataset

El proyecto utiliza tres archivos CSV principales:

### Clientes

Contiene información relacionada con los clientes de la empresa.

| Campo          | Descripción                     |
| -------------- | ------------------------------- |
| `CustomerID`   | Identificador único del cliente |
| `CustomerName` | Nombre del cliente              |
| `Region`       | Región geográfica del cliente   |
| `SignupDate`   | Fecha de registro del cliente   |

### Productos

Contiene información sobre los productos comercializados.

| Campo         | Descripción                      |
| ------------- | -------------------------------- |
| `ProductID`   | Identificador único del producto |
| `ProductName` | Nombre del producto              |
| `Category`    | Categoría del producto           |
| `Price`       | Precio del producto              |

### Transacciones

Contiene el detalle de las operaciones de venta.

| Campo             | Descripción                           |
| ----------------- | ------------------------------------- |
| `TransactionID`   | Identificador único de la transacción |
| `CustomerID`      | Identificador del cliente             |
| `ProductID`       | Identificador del producto            |
| `TransactionDate` | Fecha y hora de la transacción        |
| `Quantity`        | Cantidad de unidades vendidas         |
| `TotalValue`      | Valor total de la transacción         |
| `Price`           | Precio unitario                       |

---

## Modelo de datos

Las tres tablas se relacionan mediante identificadores:

```text
CLIENTES
   │
   │ CustomerID
   │
   ▼
TRANSACCIONES
   │
   │ ProductID
   │
   ▼
PRODUCTOS
```

### Relaciones principales

* `clientes.customer_id` → `transacciones.customer_id`
* `productos.product_id` → `transacciones.product_id`

La tabla `transacciones` funciona como tabla central del análisis, relacionando clientes y productos.

---

## Tecnologías utilizadas

* **PostgreSQL**
* **pgAdmin 4**
* **SQL**
* **GitHub**

---

## Preparación y validación de los datos

Antes de realizar los análisis se llevaron a cabo diferentes controles para verificar la calidad y consistencia de los datos.

### Verificación de cantidad de registros

Se realizó un conteo de registros para las tres tablas principales:

```sql
SELECT 'clientes' AS tabla, COUNT(*) AS filas FROM clientes
UNION ALL
SELECT 'productos', COUNT(*) FROM productos
UNION ALL
SELECT 'transacciones', COUNT(*) FROM transacciones;
```

Esto permitió verificar la cantidad de registros cargados en cada tabla.

---

### Verificación de valores nulos

Se revisaron los principales campos de las tablas para identificar posibles valores `NULL`.

En la tabla `transacciones` se verificaron:

* Fecha de transacción.
* Valor total.
* Precio.
* Cantidad.

En `clientes`:

* Región.
* Fecha de alta.

En `productos`:

* Precio.
* Categoría.
* Nombre del producto.

Los controles realizados NO SE DETECTARON VALORES NULOS que impidan continuar con el análisis.

---

### Validación de la relación cantidad × precio

Se verificó que el valor total de las transacciones fuera consistente con la cantidad vendida y el precio unitario:

```sql
SELECT COUNT(*) AS filas_inconsistentes
FROM transacciones
WHERE total_value <> quantity * price;
```

No se detectaron inconsistencias entre `TotalValue`, `Quantity` y `Price`.

---

### Detección de valores inválidos

También se verificaron cantidades, precios y valores totales menores o iguales a cero:

```sql
SELECT COUNT(*) AS valores_invalidos
FROM transacciones
WHERE quantity <= 0
   OR price <= 0
   OR total_value <= 0;
```

No se encontraron valores inválidos en estas variables.

---

## Análisis realizados

## 1. Top 5 clientes por volumen de compras

El primer análisis busca identificar a los clientes con mayor volumen total de compras.

Para ello se combinaron las tablas `transacciones` y `clientes` mediante un `JOIN`, agrupando posteriormente las operaciones por cliente.

Se utilizó `COALESCE()` como mecanismo de protección para reconstruir el valor de una transacción a partir de `quantity * price` en caso de que `total_value` estuviera vacío.

### Principales resultados

| Posición | Cliente       | Región        | Gasto total | Cantidad de compras |
| -------: | ------------- | ------------- | ----------: | ------------------: |
|        1 | Paul Parsons  | Europe        |   10.673,87 |                  10 |
|        2 | Bruce Rhodes  | Asia          |    8.040,39 |                   8 |
|        3 | Gerald Hines  | North America |    7.663,70 |                  10 |
|        4 | William Adams | North America |    7.634,45 |                  11 |
|        5 | Aimee Taylor  | South America |    7.572,91 |                   7 |

### Interpretación

El análisis permite identificar clientes de alto valor que podrían ser considerados para estrategias de fidelización, promociones personalizadas o programas de beneficios.

Paul Parsons presenta el mayor gasto acumulado, con un total de **10.673,87**, mientras que los restantes clientes del Top 5 presentan valores superiores a 7.500.

---

## 2. Evolución mensual de las ventas

El segundo análisis busca identificar la evolución temporal de las ventas.

Para agrupar las transacciones por mes se utilizó:

```sql
DATE_TRUNC('month', transaction_date)
```

Esta función permite transformar las fechas y horas de las transacciones en períodos mensuales comparables.

### Resultados

| Mes             | Ventas totales | Transacciones |
| --------------- | -------------: | ------------: |
| Diciembre 2023  |       3.769,52 |             4 |
| Enero 2024      |      66.376,39 |           107 |
| Febrero 2024    |      51.459,27 |            77 |
| Marzo 2024      |      47.828,73 |            80 |
| Abril 2024      |      57.519,06 |            86 |
| Mayo 2024       |      64.527,74 |            86 |
| Junio 2024      |      48.771,18 |            69 |
| Julio 2024      |      71.366,39 |            96 |
| Agosto 2024     |      63.436,74 |            94 |
| Septiembre 2024 |      70.603,75 |            96 |
| Octubre 2024    |      47.063,22 |            70 |
| Noviembre 2024  |      38.224,37 |            57 |
| Diciembre 2024  |      59.049,20 |            78 |

### Interpretación

El período analizado muestra variaciones importantes en el volumen mensual de ventas.

Julio de 2024 presenta el mayor volumen de ventas, con **71.366,39**, seguido por septiembre con **70.603,75** y enero con **66.376,39**.

Por otro lado, noviembre registra el menor volumen de ventas del año 2024, con **38.224,37**.

Este análisis puede utilizarse como punto de partida para estudiar posibles patrones de estacionalidad y planificar campañas comerciales, inventario y acciones promocionales.

---

## 3. Productos con menor cantidad de unidades vendidas

El tercer análisis busca identificar productos con baja rotación.

Se utilizó un `LEFT JOIN` desde la tabla `productos` hacia `transacciones`. De esta manera se mantienen también los productos que eventualmente no hubieran registrado ventas.

La cantidad de unidades vendidas se calculó mediante:

```sql
COALESCE(SUM(t.quantity), 0)
```

### Resultados

| Posición | Producto               | Categoría   | Unidades vendidas |
| -------: | ---------------------- | ----------- | ----------------: |
|        1 | SoundWave Headphones   | Electronics |                 9 |
|        2 | SoundWave Mystery Book | Books       |                11 |
|        3 | SoundWave Cookbook     | Books       |                12 |

### Interpretación

Estos productos presentan los niveles más bajos de unidades vendidas dentro del conjunto analizado.

Esta información puede ser utilizada para evaluar diferentes alternativas comerciales, como promociones, descuentos, cambios en la estrategia de comercialización o revisión del nivel de inventario.

La decisión sobre qué acción implementar requeriría complementar este análisis con variables adicionales, como margen de rentabilidad, stock disponible y costos asociados.

---

## 4. Ranking de las principales transacciones por categoría

El último análisis busca identificar las transacciones de mayor valor dentro de cada categoría de productos.

Para realizarlo se utilizó una **CTE (Common Table Expression)** junto con la función de ventana:

```sql
RANK() OVER (
    PARTITION BY p.category
    ORDER BY t.total_value DESC
)
```

La utilización de `PARTITION BY` permite generar un ranking independiente para cada categoría.

### Resultado

Las principales transacciones identificadas fueron:

#### Books

| Ranking | Transaction ID |    Valor |
| ------: | -------------- | -------: |
|       1 | T00928         | 1.991,04 |
|       2 | T00499         | 1.954,52 |
|       3 | T00070         | 1.879,08 |

Se registraron además varias transacciones empatadas en el tercer puesto con un valor de **1.879,08**.

#### Clothing

| Ranking | Transaction ID |    Valor |
| ------: | -------------- | -------: |
|       1 | T00307         | 1.927,12 |
|       2 | T00552         | 1.809,68 |
|       2 | T00109         | 1.809,68 |

#### Electronics

| Ranking | Transaction ID |    Valor |
| ------: | -------------- | -------: |
|       1 | T00922         | 1.839,44 |
|       2 | T00482         | 1.825,12 |
|       2 | T00012         | 1.825,12 |

También se registraron otras transacciones empatadas con el segundo puesto.

#### Home Decor

| Ranking | Transaction ID |    Valor |
| ------: | -------------- | -------: |
|       1 | T00007         | 1.818,12 |
|       1 | T00997         | 1.818,12 |
|       3 | T00912         | 1.789,36 |

### Consideración sobre los empates

Se utilizó `RANK()` en lugar de `ROW_NUMBER()` porque permite conservar los empates.

Por esta razón, el resultado puede contener más de tres transacciones en una categoría cuando varias operaciones tienen exactamente el mismo valor.

Por ejemplo, en la categoría **Books**, varias transacciones comparten el tercer puesto con un valor de **1.879,08**.

Esto permite conservar toda la información relevante en lugar de seleccionar arbitrariamente una sola transacción.

---

## Principales conceptos y funciones SQL utilizados

Durante el desarrollo del proyecto se utilizaron diferentes herramientas y conceptos de SQL:

### `JOIN`

Se utilizó para relacionar información entre clientes, productos y transacciones.

```sql
JOIN clientes c
    ON c.customer_id = t.customer_id
```

### `LEFT JOIN`

Se utilizó para conservar todos los productos, incluso aquellos que no tuvieran transacciones asociadas.

### `GROUP BY`

Permitió agrupar información para calcular métricas por cliente, mes o producto.

### `ORDER BY`

Se utilizó para ordenar los resultados según diferentes métricas.

### `LIMIT`

Permitió obtener subconjuntos específicos de resultados, como el Top 5 de clientes.

### `COALESCE()`

Se utilizó para manejar valores nulos y proporcionar un valor alternativo.

### `DATE_TRUNC()`

Permitió agrupar las transacciones por mes.

### `CTE`

Se utilizó una **Common Table Expression** para construir el ranking de transacciones por categoría.

### Funciones de ventana

Se utilizó:

```sql
RANK() OVER (...)
```

para generar rankings independientes dentro de cada categoría.

### `FILTER`

Se utilizó para realizar controles específicos sobre valores nulos:

```sql
COUNT(*) FILTER (WHERE ...)
```

---

## Principales conclusiones

- **Las ventas no dependen de pocos clientes.** El Top 5 suma ~41.585, apenas el 6% de las
  ventas totales (~690.000). Hay dos perfiles: Aimee Taylor compra poco pero caro
  (ticket promedio ~1.082) y William Adams compra seguido con tickets bajos (~694).
  Conviene fidelizar al segundo y ofrecer productos premium a la primera.
- **Julio y septiembre son los meses más fuertes; noviembre, el más débil** (38.224,
  casi la mitad que julio), con un rebote de +54% en diciembre. Julio vende más que
  enero con menos transacciones, porque su ticket promedio es mayor.
  *Limitación:* hay solo un año de datos, así que esto es una hipótesis de estacionalidad
  y no una conclusión firme. Diciembre de 2023 tiene solo 4 transacciones (el dataset
  empieza a fin de mes), por lo que no es comparable.
- **Los tres productos menos vendidos pertenecen a la línea "SoundWave"**, lo que sugiere
  revisar precio, visibilidad o demanda de esa línea. Ningún producto tuvo cero ventas.
  Se verificó que no hay empates en el tercer puesto.
- **Los pedidos más grandes son parejos entre categorías** (entre 1.800 y 2.000):
  ninguna categoría concentra los tickets altos.
- **Calidad de datos:** no se detectaron nulos, valores inválidos ni inconsistencias entre
  `total_value` y `quantity × price`.
---

## Cómo ejecutar el código

1. Crear la base de datos (conectado a `postgres`):
```sql
   CREATE DATABASE capstone_project;
```
2. Conectarse a `capstone_project` y ejecutar `estructura.sql` (crea las tres tablas).
3. Importar los CSV en este orden: `clientes`, `productos`, `transacciones`.
   En pgAdmin: clic derecho sobre la tabla → *Import/Export Data* → formato `csv`,
   encoding `UTF8`, opción *Header* activada, delimitador `,`.
4. Ejecutar `analisis.sql` consulta por consulta.

---

## Estructura del repositorio

```text
capstone_project/
│
├── README.md
├── estructura.sql
└── analisis.sql
```

### `estructura.sql`

Contiene las instrucciones relacionadas con la creación y preparación de las tablas utilizadas en el proyecto.

### `analisis.sql`

Contiene las consultas SQL desarrolladas para realizar los análisis de clientes, ventas, productos y categorías.

### `README.md`

Documenta el proyecto, el dataset utilizado, los controles realizados, las consultas desarrolladas y los principales resultados obtenidos.

---

## Autor

**Martín Alejandro Tejada Lara**

Proyecto realizado como parte de una instancia de formación en análisis de datos y SQL.
