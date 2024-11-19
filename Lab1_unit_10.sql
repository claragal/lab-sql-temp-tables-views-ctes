USE sakila;

-- Create view
CREATE VIEW customer_rental_summary AS
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    COUNT(r.rental_id) AS rental_count
FROM customer c
LEFT JOIN rental r ON c.customer_id = r.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email;


/*-- Create temporary table. Mi versión.
Feedback: La decisión de utilizar LEFT JOIN nuevamente para asegurar que todos los clientes estuvieran incluídos es interesante, 
pero hay instancias donde un JOIN directo podría ser más adecuado dependiendo de si necesitas excluir aquellos sin pagos registrados.

CREATE TEMPORARY TABLE customer_payment_summary AS
SELECT 
    c.customer_id,
    SUM(p.amount) AS total_paid
FROM customer c
LEFT JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id;
*/


-- Corregido por feedback Ironhack
-- Crear una tabla temporal para el total pagado por cada cliente
CREATE TEMPORARY TABLE customer_payment_summary AS
SELECT
    rv.customer_id,
    SUM(p.amount) AS total_paid
FROM
    customer_rental_summary crs
JOIN
    payment p ON crs.customer_id = p.customer_id
GROUP BY
    crs.customer_id;


/*-- Create CTE and Customer Summary Report. Mi versión.
Feedback: El feedback sugiere que el cálculo de average_payment_per_rental sea realizado después de haber recuperado todos los datos mediante el CTE. 
Esto ayuda a evitar errores de cálculo durante la transmisión de datos.
WITH customer_summary_cte AS (
    SELECT 
        crs.customer_name,
        crs.email,
        crs.rental_count,
        IFNULL(cps.total_paid, 0) AS total_paid, -- Handle nulls
        CASE 
            WHEN crs.rental_count > 0 THEN IFNULL(cps.total_paid, 0) / crs.rental_count
            ELSE 0
        END AS average_payment_per_rental
    FROM customer_rental_summary crs
    LEFT JOIN customer_payment_summary cps 
        ON crs.customer_id = cps.customer_id
)
SELECT 
    customer_name,
    email,
    rental_count,
    total_paid,
    ROUND(average_payment_per_rental, 2) AS average_payment_per_rental
FROM customer_summary_cte
ORDER BY customer_name;
*/

-- Create CTE and Customer Summary Report. Corregida
-- Crear el CTE para combinar el resumen de alquileres y los pagos del cliente
WITH customer_summary_cte AS (
    SELECT
        crs.customer_id,
        crs.customer_name,
        crs.email,
        crs.rental_count,
        cps.total_paid
    FROM
        customer_rental_summary crs
    JOIN
        customer_payment_summary cps ON crs.customer_id = cps.customer_id
)

-- Generar el reporte final de resumen del cliente
SELECT
    csc.customer_name,
    csc.email,
    csc.rental_count,
    csc.total_paid,
    csc.total_paid / csc.rental_count AS average_payment_per_rental
FROM
    customer_summary_cte csc;
