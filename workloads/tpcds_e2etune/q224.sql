WITH st AS (
    SELECT
        t.t_hour,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    GROUP BY t.t_hour
),
wb AS (
    SELECT
        t.t_hour,
        w.w_city,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS web_transactions
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY t.t_hour, w.w_city
),
wr AS (
    SELECT
        t.t_hour,
        w.w_city,
        SUM(wr.wr_net_loss) AS return_net_loss,
        SUM(wr.wr_return_amt_inc_tax) AS return_amount,
        COUNT(DISTINCT wr.wr_order_number) AS return_transactions
    FROM web_returns wr
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY t.t_hour, w.w_city
)
SELECT
    wb.t_hour,
    wb.w_city,
    wb.web_net_profit,
    st.store_net_profit,
    COALESCE(wr.return_net_loss, 0) AS return_net_loss,
    (wb.web_net_profit + st.store_net_profit - COALESCE(wr.return_net_loss, 0)) AS total_net_profit,
    wb.web_quantity,
    st.store_quantity,
    COALESCE(wr.return_amount, 0) AS return_amount
FROM wb
JOIN st ON wb.t_hour = st.t_hour
LEFT JOIN wr ON wb.t_hour = wr.t_hour AND wb.w_city = wr.w_city
WHERE wb.w_city IN ('New York', 'Los Angeles', 'Chicago')
  AND wb.t_hour BETWEEN 9 AND 21
ORDER BY total_net_profit DESC
LIMIT 100
