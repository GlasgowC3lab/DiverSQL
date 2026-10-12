WITH ss AS (
    SELECT *
    FROM store_sales
    WHERE ss_quantity > 3
      AND ss_net_paid_inc_tax > 500.00
),
ws AS (
    SELECT *
    FROM web_sales
    WHERE ws_quantity > 2
      AND ws_net_paid_inc_tax > 300.00
),
cr AS (
    SELECT *
    FROM catalog_returns
    WHERE cr_return_quantity > 0
      AND cr_return_amount > 20.00
)
SELECT
    s.s_store_name,
    cc.cc_name,
    sm.sm_type,
    td.t_hour,
    wp.wp_type,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(ss.ss_net_paid_inc_tax) AS total_store_sales,
    SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
    SUM(cr.cr_return_amount) AS total_return_amount,
    MIN(ss.ss_sold_date_sk) AS first_store_sale_date_sk,
    MAX(ws.ws_sold_date_sk) AS last_web_sale_date_sk
FROM ss
RIGHT OUTER JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
LEFT JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN cr
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE
    td.t_hour = 14
    AND s.s_state = 'CA'
    AND cc.cc_manager = 'Larry Mccray'
    AND wp.wp_url = 'http://www.foo.com'
GROUP BY
    s.s_store_name,
    cc.cc_name,
    sm.sm_type,
    td.t_hour,
    wp.wp_type
ORDER BY total_store_sales DESC
LIMIT 100
