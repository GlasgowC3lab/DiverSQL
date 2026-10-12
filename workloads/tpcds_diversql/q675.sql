WITH ws_sample AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
),

orders_with_returns AS (
    SELECT ws.ws_order_number
    FROM ws_sample ws
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
),

orders_with_catalog_returns AS (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2450100
),

common_return_orders AS (
    SELECT ws_order_number FROM orders_with_returns
    INTERSECT
    SELECT cr_order_number FROM orders_with_catalog_returns
),

ws_not_in_catalog AS (
    SELECT ws_order_number FROM ws_sample
    EXCEPT
    SELECT cr_order_number FROM orders_with_catalog_returns
)
SELECT
    sm.sm_type,
    td.t_hour,
    r.r_reason_desc,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
    MAX(ws.ws_quantity) AS max_quantity,
    COUNT(*) AS order_count,
    SUM(CASE WHEN sm.sm_type = 'AIR' THEN ws.ws_net_profit ELSE 0 END) AS air_mode_profit,
    COUNT(DISTINCT i.i_brand) AS distinct_brands
FROM ws_sample ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
LEFT JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
WHERE
    td.t_shift = 'first'
    AND sm.sm_contract = 'OrDuVy2H'
    AND cd_bill.cd_credit_rating = 'Good'
    AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
    AND ws.ws_order_number IN (SELECT ws_order_number FROM common_return_orders)
    AND ws.ws_order_number NOT IN (SELECT ws_order_number FROM ws_not_in_catalog)
GROUP BY
    sm.sm_type,
    td.t_hour,
    r.r_reason_desc
HAVING COUNT(*) > 10
ORDER BY total_net_profit DESC
LIMIT 100
