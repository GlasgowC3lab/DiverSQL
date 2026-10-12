WITH intersect_orders AS (
        SELECT ws_order_number FROM web_sales WHERE ws_quantity > 10
        INTERSECT
        SELECT ws_order_number FROM web_sales WHERE ws_net_profit > 0
    ),
    eligible_sales AS (
        SELECT ss_ticket_number FROM store_sales WHERE ss_quantity = 0
    )
SELECT
    td1.t_sub_shift AS sale_sub_shift,
    p1.p_promo_name AS promo_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_count,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ws.ws_net_paid) AS total_web_net_paid,
    COUNT(DISTINCT intersect_orders.ws_order_number) AS intersect_order_count
FROM
    (SELECT * FROM store_sales TABLESAMPLE BERNOULLI (10)) ss
JOIN time_dim td1
    ON ss.ss_sold_time_sk = td1.t_time_sk
JOIN promotion p1
    ON ss.ss_promo_sk = p1.p_promo_sk
JOIN web_sales ws
    ON ws.ws_sold_time_sk = td1.t_time_sk
JOIN promotion p2
    ON ws.ws_promo_sk = p2.p_promo_sk
JOIN time_dim td2
    ON ws.ws_sold_time_sk = td2.t_time_sk
JOIN catalog_returns cr
    ON cr.cr_returned_time_sk = td2.t_time_sk
JOIN time_dim td3
    ON cr.cr_returned_time_sk = td3.t_time_sk
JOIN time_dim td4
    ON ss.ss_sold_time_sk = td4.t_time_sk
JOIN promotion p3
    ON ss.ss_promo_sk = p3.p_promo_sk
LEFT JOIN intersect_orders
    ON ws.ws_order_number = intersect_orders.ws_order_number
WHERE
    ss.ss_ticket_number NOT IN (SELECT ss_ticket_number FROM eligible_sales)
GROUP BY
    td1.t_sub_shift,
    p1.p_promo_name
ORDER BY
    total_net_paid DESC
LIMIT 100
