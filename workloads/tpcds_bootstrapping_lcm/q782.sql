WITH item_sales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS item_total_profit
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
item_avg_profit AS (
    SELECT AVG(item_total_profit) AS avg_profit
    FROM item_sales
)
SELECT
    d_sold.d_year,
    d_sold.d_current_month,
    i.i_category,
    i.i_brand,
    s.s_state,
    wp.wp_type,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    ROUND(SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0), 4) AS profit_margin,
    CASE
        WHEN SUM(ws.ws_net_profit) > (SELECT avg_profit FROM item_avg_profit) THEN 'Above Avg Profit'
        ELSE 'Below Avg Profit'
    END AS profit_category,
    RANK() OVER (PARTITION BY i.i_category ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank_within_category
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
GROUP BY
    d_sold.d_year,
    d_sold.d_current_month,
    i.i_category,
    i.i_brand,
    s.s_state,
    wp.wp_type
HAVING SUM(ws.ws_ext_sales_price) > 1000
ORDER BY total_profit DESC
LIMIT 100
