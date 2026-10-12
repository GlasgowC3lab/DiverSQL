WITH
    high_profit_orders AS (
        SELECT
            ws.ws_order_number,
            ws.ws_net_profit,
            p.p_promo_name
        FROM
            web_sales ws
            JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        WHERE
            ws.ws_net_profit > (SELECT avg(ws_net_profit) FROM web_sales)
    ),
    returned_orders AS (
        SELECT cr.cr_order_number
        FROM catalog_returns cr
    ),
    candidate_order_numbers AS (
        SELECT ws_order_number
        FROM high_profit_orders
        EXCEPT
        SELECT cr_order_number
        FROM returned_orders
    )
SELECT
    discount_percent,
    COUNT(*) AS order_cnt,
    SUM(ws_net_profit) AS total_profit,
    MIN(ws_order_number) AS example_order_number
FROM (
    SELECT
        hp.ws_order_number,
        hp.ws_net_profit,
        hp.p_promo_name,
        regexp_extract(hp.p_promo_name, '(\\d+)%', 1) AS discount_percent,
        CONCAT('Order_', CAST(hp.ws_order_number AS VARCHAR)) AS order_label
    FROM
        high_profit_orders hp
        JOIN candidate_order_numbers c ON hp.ws_order_number = c.ws_order_number
    WHERE
        hp.p_promo_name LIKE '%Summer%'
        AND regexp_like(hp.p_promo_name, '\\d+%')
) t
GROUP BY
    discount_percent
ORDER BY
    total_profit DESC
LIMIT 100
