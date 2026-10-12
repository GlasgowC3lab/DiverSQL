WITH sales_agg AS (
    SELECT
        sm.sm_carrier,
        sm.sm_ship_mode_id,
        COALESCE(r.r_reason_desc, 'No Return') AS return_reason,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
        AND sm.sm_carrier = 'UPS'
    GROUP BY sm.sm_carrier, sm.sm_ship_mode_id, COALESCE(r.r_reason_desc, 'No Return')
    HAVING SUM(ws.ws_net_profit) > 0
)
SELECT
    sm_carrier,
    sm_ship_mode_id,
    return_reason,
    total_sales,
    total_profit,
    total_return_amount,
    CASE WHEN total_sales = 0 THEN 0 ELSE total_return_amount / total_sales END AS return_rate,
    avg_discount,
    num_orders,
    RANK() OVER (PARTITION BY return_reason ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_profit DESC
LIMIT 50
