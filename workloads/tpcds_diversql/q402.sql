WITH sales_hdemo AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ext_wholesale_cost,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_web_page_sk,
        hd.hd_demo_sk,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        hd.hd_income_band_sk,
        ib.ib_upper_bound,
        ib.ib_lower_bound,
        wp.wp_type,
        wp.wp_char_count,
        wp.wp_link_count
    FROM web_sales ws
    FULL OUTER JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    INNER JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    INNER JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451178 AND 2452342
      AND ib.ib_upper_bound >= 100000
      AND hd.hd_vehicle_count >= 0
      AND wp.wp_type = 'content'
      AND ws.ws_ext_wholesale_cost > 2000
)
SELECT
    sh.hd_income_band_sk,
    CASE
        WHEN sh.ib_upper_bound > 150000 THEN 'High Income'
        ELSE 'Mid Income'
    END AS income_category,
    COUNT(DISTINCT sh.ws_order_number) AS order_cnt,
    SUM(sh.ws_net_paid_inc_ship_tax) AS total_net_paid,
    AVG(sh.ws_ext_wholesale_cost) AS avg_wholesale_cost,
    MIN(sh.ws_ext_wholesale_cost) AS min_wholesale,
    MAX(sh.ws_ext_wholesale_cost) AS max_wholesale,
    lt.line_total,
    t.key   AS metric,
    t.value AS metric_val
FROM sales_hdemo sh
-- LATERAL subquery to compute line total per order line
CROSS JOIN LATERAL (
    SELECT sh.ws_quantity * sh.ws_sales_price AS line_total
) lt
-- Build a map of page metrics and unnest it
CROSS JOIN LATERAL (
    SELECT MAP(ARRAY['char_count','link_count'], ARRAY[sh.wp_char_count, sh.wp_link_count]) AS metric_map
) mm
CROSS JOIN UNNEST(mm.metric_map) AS t(key, value)
GROUP BY
    sh.hd_income_band_sk,
    CASE
        WHEN sh.ib_upper_bound > 150000 THEN 'High Income'
        ELSE 'Mid Income'
    END,
    lt.line_total,
    t.key,
    t.value
LIMIT 100
