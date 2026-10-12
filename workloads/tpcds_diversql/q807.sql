WITH sampled_web_sales AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ws_quantity > 0
)

SELECT
    'Web Promo' AS source,
    CONCAT('Promo_', REGEXP_EXTRACT(p.p_promo_name, '(\\w+)', 1)) AS key,
    SUM(ws.ws_ext_sales_price) AS metric1,
    COUNT(DISTINCT ws.ws_order_number) AS metric2
FROM sampled_web_sales ws
FULL OUTER JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
WHERE p.p_promo_name LIKE '%Clearance%'
  AND REGEXP_LIKE(p.p_promo_name, '^[A-Z]')
GROUP BY CONCAT('Promo_', REGEXP_EXTRACT(p.p_promo_name, '(\\w+)', 1))
HAVING SUM(ws.ws_ext_sales_price) > 10000

UNION

SELECT
    'Store Return' AS source,
    CONCAT('Vehicle_', CAST(hd.hd_vehicle_count AS VARCHAR)) AS key,
    SUM(sr.sr_return_amt_inc_tax) AS metric1,
    COUNT(*) AS metric2
FROM store_returns sr
JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_vehicle_count >= 0
  AND REGEXP_LIKE(CAST(hd.hd_vehicle_count AS VARCHAR), '^\\d+$')
GROUP BY CONCAT('Vehicle_', CAST(hd.hd_vehicle_count AS VARCHAR))
HAVING SUM(sr.sr_return_amt_inc_tax) > 5000

ORDER BY metric1 DESC
LIMIT 100
