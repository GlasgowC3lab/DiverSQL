WITH sales_by_cc AS (
    SELECT
        cc.cc_state,
        ib.ib_income_band_sk,
        sum(ws.ws_net_paid) AS total_net_paid,
        avg(ws.ws_net_profit) AS avg_profit,
        sum(ws.ws_quantity) AS total_quantity,
        count(distinct ws.ws_order_number) AS distinct_orders
    FROM call_center cc
    JOIN web_sales ws
        ON cc.cc_open_date_sk = ws.ws_sold_date_sk
    JOIN income_band ib
        ON cc.cc_employees >= ib.ib_lower_bound
        AND cc.cc_employees < ib.ib_upper_bound
    WHERE cc.cc_state = 'CA'
      AND ws.ws_net_paid > 0
      AND ws.ws_ship_mode_sk IN (1, 2, 3)
    GROUP BY cc.cc_state, ib.ib_income_band_sk
)
SELECT
    cc_state,
    ib_income_band_sk,
    total_net_paid,
    avg_profit,
    total_quantity,
    distinct_orders,
    rank() OVER (ORDER BY total_net_paid DESC) AS revenue_rank
FROM sales_by_cc
ORDER BY revenue_rank
LIMIT 10
