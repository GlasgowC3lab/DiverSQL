/*
  Goal: Identify high‑value catalog returns by joining all five selected TPC‑DS tables, re‑using the customer and date_dim tables under multiple aliases, applying a variety of advanced Trino features (FULL OUTER JOIN, EXCEPT, scalar subquery, TABLESAMPLE, LATERAL, and extensive joins), then ordering and limiting the result.
*/
WITH sampled_returns AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (5)  -- sample ~5 % of the rows
),
refunded_cust AS (
    SELECT c.*, ds.d_date AS first_ship_date, da.d_date AS first_sales_date
    FROM customer c
    JOIN date_dim ds ON c.c_first_shipto_date_sk = ds.d_date_sk   -- join 1
    JOIN date_dim da ON c.c_first_sales_date_sk = da.d_date_sk   -- join 2
),
returning_cust AS (
    SELECT * FROM customer
),
date_start AS (
    SELECT * FROM date_dim WHERE d_year = 2001
),
date_end AS (
    SELECT * FROM date_dim WHERE d_year = 2003
),
store_closed AS (
    SELECT s.*, dc.d_date AS closed_date
    FROM store s
    LEFT JOIN date_dim dc ON s.s_closed_date_sk = dc.d_date_sk   -- join 3
)
SELECT *
FROM (
    SELECT
        s.s_store_id,
        cp.cp_catalog_page_id,
        d_ret.d_date         AS return_date,
        cu_ref.c_customer_id AS refunded_customer_id,
        cu_ret.c_customer_id AS returning_customer_id,
        lt.line_total,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        AVG(cr.cr_fee) AS avg_fee
    FROM sampled_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk                 -- join 4
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk           -- join 5
    JOIN refunded_cust cu_ref ON cr.cr_refunded_customer_sk = cu_ref.c_customer_sk -- join 6
    JOIN returning_cust cu_ret ON cr.cr_returning_customer_sk = cu_ret.c_customer_sk -- join 7
    JOIN date_start d_start ON cp.cp_start_date_sk = d_start.d_date_sk            -- join 8
    JOIN date_end d_end ON cp.cp_end_date_sk = d_end.d_date_sk                    -- join 9
    FULL OUTER JOIN store_closed s ON s.s_store_sk = cr.cr_warehouse_sk           -- full outer join 10
    CROSS JOIN LATERAL (
        SELECT cr.cr_return_quantity * cr.cr_return_amount AS line_total
    ) lt                                                                        -- lateral subquery
    WHERE cr.cr_fee > (
        SELECT AVG(inner_cr.cr_fee)
        FROM catalog_returns inner_cr
        WHERE inner_cr.cr_fee < 10
    )                                                                        -- scalar subquery filter
    GROUP BY
        s.s_store_id,
        cp.cp_catalog_page_id,
        d_ret.d_date,
        cu_ref.c_customer_id,
        cu_ret.c_customer_id,
        lt.line_total
    HAVING SUM(cr.cr_return_amount) > 0
) q1
EXCEPT
SELECT
    s_store_id,
    cp_catalog_page_id,
    return_date,
    refunded_customer_id,
    returning_customer_id,
    line_total,
    total_return_amount,
    distinct_orders,
    avg_fee
FROM (
    SELECT
        s.s_store_id        AS s_store_id,
        cp.cp_catalog_page_id AS cp_catalog_page_id,
        d_ret.d_date        AS return_date,
        cu_ref.c_customer_id AS refunded_customer_id,
        cu_ret.c_customer_id AS returning_customer_id,
        lt.line_total,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        AVG(cr.cr_fee) AS avg_fee
    FROM sampled_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN refunded_cust cu_ref ON cr.cr_refunded_customer_sk = cu_ref.c_customer_sk
    JOIN returning_cust cu_ret ON cr.cr_returning_customer_sk = cu_ret.c_customer_sk
    JOIN date_start d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_end d_end ON cp.cp_end_date_sk = d_end.d_date_sk
    FULL OUTER JOIN store_closed s ON s.s_store_sk = cr.cr_warehouse_sk
    CROSS JOIN LATERAL (
        SELECT cr.cr_return_quantity * cr.cr_return_amount AS line_total
    ) lt
    WHERE FALSE  -- guarantees an empty set for the EXCEPT operand
    GROUP BY
        s.s_store_id,
        cp.cp_catalog_page_id,
        d_ret.d_date,
        cu_ref.c_customer_id,
        cu_ret.c_customer_id,
        lt.line_total
) q2
ORDER BY total_return_amount DESC
LIMIT 100
