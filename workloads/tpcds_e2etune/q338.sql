WITH sales_agg AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        wp.wp_type AS page_type,
        ws.ws_sold_date_sk AS sold_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid) AS avg_paid,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_net_paid), 0) AS profit_to_paid_ratio
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
      AND wp.wp_type IN ('home', 'product', 'search')
      AND w.w_city = 'San Francisco'
    GROUP BY w.w_warehouse_name, wp.wp_type, ws.ws_sold_date_sk
    HAVING SUM(ws.ws_net_profit) > 10000
)
SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY warehouse_name ORDER BY total_profit DESC) AS profit_rank_in_warehouse
FROM sales_agg
ORDER BY total_profit DESC
LIMIT 200
