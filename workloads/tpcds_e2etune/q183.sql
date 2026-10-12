SELECT
    q.i_category,
    q.sm_type,
    q.t_hour,
    q.orders,
    q.total_quantity,
    q.total_sales,
    q.total_profit,
    q.avg_discount,
    RANK() OVER (PARTITION BY q.sm_type ORDER BY q.total_profit DESC) AS profit_rank
FROM (
    SELECT
        i.i_category,
        sm.sm_type,
        t.t_hour,
        COUNT(DISTINCT ws.ws_order_number) AS orders,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451088
      AND sm.sm_type IN ('AIR', 'GROUND', 'RAIL')
      AND wp.wp_type = 'product'
    GROUP BY i.i_category, sm.sm_type, t.t_hour
    HAVING SUM(ws.ws_net_profit) > 0
) q
ORDER BY q.sm_type, profit_rank, q.i_category
