WITH eligible_warehouses AS (
    SELECT w_warehouse_sk
    FROM warehouse
    WHERE w_country = 'United States'
    EXCEPT
    SELECT w_warehouse_sk
    FROM warehouse
    WHERE w_gmt_offset = -5.00
)
SELECT
    w.w_city,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(cr.cr_order_number)                AS returns_cnt,
    SUM(cr.cr_return_amount)                AS total_return_amount,
    AVG(cr.cr_return_amount)                AS avg_return_amount,
    REGEXP_EXTRACT(w.w_warehouse_name, '(\\w+)', 1) AS first_word_name,
    SUBSTRING(w.w_warehouse_name FROM 1 FOR 5)   AS short_name
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN household_demographics hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    REGEXP_LIKE(w.w_city, '^New|town$')
    AND w.w_warehouse_name LIKE '%Warehouse%'
    AND d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    AND cr.cr_warehouse_sk IN (
        SELECT w_warehouse_sk FROM warehouse WHERE w_country = 'United States'
    )
    AND cr.cr_warehouse_sk IN (SELECT w_warehouse_sk FROM eligible_warehouses)
GROUP BY
    w.w_city,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    REGEXP_EXTRACT(w.w_warehouse_name, '(\\w+)', 1),
    SUBSTRING(w.w_warehouse_name FROM 1 FOR 5)
ORDER BY total_return_amount DESC
LIMIT 100
