WITH sales_pre AS (
    SELECT
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        sm_dim.sm_type,
        ca_bill.ca_state AS billing_state,
        wp_main.wp_type AS page_type,
        LAG(ws.ws_net_profit) OVER (PARTITION BY sm_dim.sm_type ORDER BY ws.ws_sold_date_sk) AS lag_net_profit,
        CASE WHEN EXISTS (
            SELECT 1
            FROM (
                SELECT ws2.ws_web_page_sk
                FROM web_sales ws2
                EXCEPT
                SELECT wp2.wp_web_page_sk
                FROM web_page wp2
            ) diff
            WHERE diff.ws_web_page_sk = ws.ws_web_page_sk
        ) THEN 'OnlySales' ELSE 'Both' END AS page_presence
    FROM web_sales ws
    RIGHT OUTER JOIN ship_mode sm_dim
        ON ws.ws_ship_mode_sk = sm_dim.sm_ship_mode_sk
    INNER JOIN ship_mode sm_main
        ON ws.ws_ship_mode_sk = sm_main.sm_ship_mode_sk
    INNER JOIN ship_mode sm_extra1
        ON ws.ws_ship_mode_sk = sm_extra1.sm_ship_mode_sk
    INNER JOIN ship_mode sm_extra2
        ON ws.ws_ship_mode_sk = sm_extra2.sm_ship_mode_sk
    INNER JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    INNER JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    INNER JOIN web_page wp_main
        ON ws.ws_web_page_sk = wp_main.wp_web_page_sk
    INNER JOIN web_page wp_alt
        ON ws.ws_web_page_sk = wp_alt.wp_web_page_sk
    INNER JOIN web_page wp_extra
        ON ws.ws_web_page_sk = wp_extra.wp_web_page_sk
    INNER JOIN store_returns sr
        ON sr.sr_addr_sk = ca_bill.ca_address_sk
    INNER JOIN customer_address ca_return2
        ON sr.sr_addr_sk = ca_return2.ca_address_sk
)
SELECT
    sm_type,
    billing_state,
    page_type,
    SUM(ws_net_profit)                                     AS total_profit,
    COUNT(DISTINCT ws_order_number)                        AS order_cnt,
    AVG(ws_quantity)                                       AS avg_qty,
    CASE WHEN SUM(ws_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
    LAG(SUM(ws_net_profit)) OVER (PARTITION BY sm_type ORDER BY SUM(ws_net_profit) DESC) AS prev_total_profit,
    COUNT(CASE WHEN page_presence = 'OnlySales' THEN 1 END) AS only_sales_pages
FROM sales_pre
GROUP BY sm_type, billing_state, page_type
ORDER BY total_profit DESC
LIMIT 100
