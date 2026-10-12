/*
Goal: Identify the top 3 customers by net sales price within each household income band, for recent high‑value sales, and compare each sale to the overall average sales price.
*/
WITH avg_sales AS (
    SELECT avg(ss_ext_sales_price) AS avg_price
    FROM store_sales
),
ranked AS (
    SELECT
        c.c_customer_id               AS customer_id,
        c.c_first_name                AS first_name,
        c.c_last_name                 AS last_name,
        hd.hd_income_band_sk          AS income_band_sk,
        hd.hd_dep_count               AS dep_count,
        hd.hd_vehicle_count           AS vehicle_count,
        ss.ss_sold_date_sk            AS sold_date_sk,
        ss.ss_ext_sales_price         AS ext_sales_price,
        r.r_reason_desc               AS reason_desc,
        ROW_NUMBER() OVER (
            PARTITION BY hd.hd_income_band_sk
            ORDER BY ss.ss_ext_sales_price DESC
        )                            AS rn
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE
        hd.hd_income_band_sk IN (5, 7, 13, 14, 16)               -- predicate 1
        AND hd.hd_dep_count BETWEEN 1 AND 6                     -- predicate 2
        AND hd.hd_vehicle_count >= 0                           -- predicate 3
        AND ss.ss_ext_list_price > 1000                         -- predicate 4
        AND ss.ss_sold_time_sk BETWEEN 40000 AND 80000          -- predicate 5
        AND c.c_last_review_date > 2452500                      -- predicate 6
        AND ss.ss_ext_sales_price > (SELECT avg_price FROM avg_sales)  -- scalar subquery comparison
)
SELECT
    customer_id,
    first_name,
    last_name,
    income_band_sk,
    dep_count,
    vehicle_count,
    sold_date_sk,
    ext_sales_price,
    reason_desc,
    rn
FROM ranked
WHERE rn <= 3
ORDER BY income_band_sk, rn
