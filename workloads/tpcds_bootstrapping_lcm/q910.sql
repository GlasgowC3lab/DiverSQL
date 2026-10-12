WITH sales_returns AS (
    SELECT
        d_sale.d_year AS sale_year,
        d_sale.d_month_seq AS sale_month_seq,
        d_ship.d_month_seq AS ship_month_seq,
        sm.sm_carrier,
        sm.sm_type,
        s.s_city,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        SUM(ws.ws_net_profit) AS total_sales_profit,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_return_loss,
        SUM(ws.ws_net_profit) - SUM(wr.wr_net_loss) AS net_profit_after_returns,
        AVG(ws.ws_quantity) AS avg_quantity
    FROM web_sales ws
    JOIN date_dim d_sale   ON ws.ws_sold_date_sk = d_sale.d_date_sk
    JOIN date_dim d_ship   ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN ship_mode sm      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_returns wr   ON wr.wr_item_sk = ws.ws_item_sk
                           AND wr.wr_order_number = ws.ws_order_number
    JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN store s           ON s.s_closed_date_sk = d_return.d_date_sk
    WHERE d_sale.d_year = 2021
    GROUP BY
        d_sale.d_year,
        d_sale.d_month_seq,
        d_ship.d_month_seq,
        sm.sm_carrier,
        sm.sm_type,
        s.s_city
)
SELECT
    sale_year,
    sale_month_seq,
    ship_month_seq,
    sm_carrier,
    sm_type,
    s_city,
    num_orders,
    total_sales_profit,
    total_return_amount,
    total_return_loss,
    net_profit_after_returns,
    avg_quantity
FROM sales_returns
ORDER BY total_sales_profit DESC
LIMIT 50
