WITH ws_agg AS (
    SELECT
        i.i_category AS category,
        sm.sm_type AS ship_type,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS orders_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451088
      AND i.i_category = 'Electronics'
    GROUP BY i.i_category, sm.sm_type
),
sr_agg AS (
    SELECT
        i.i_category AS category,
        s.s_state AS state,
        SUM(sr.sr_net_loss) AS total_return_loss,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_tickets
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE i.i_category = 'Electronics'
      AND s.s_state IN ('CA', 'TX', 'NY')
    GROUP BY i.i_category, s.s_state
)
SELECT
    ws.category,
    ws.ship_type,
    sr.state,
    ws.total_net_profit,
    ws.total_discount,
    sr.total_return_loss,
    sr.total_return_amount,
    (ws.total_net_profit - sr.total_return_loss) AS net_margin,
    RANK() OVER (PARTITION BY sr.state ORDER BY (ws.total_net_profit - sr.total_return_loss) DESC) AS profit_rank
FROM ws_agg ws
JOIN sr_agg sr ON ws.category = sr.category
WHERE ws.total_net_profit > 10000
ORDER BY net_margin DESC
LIMIT 100
