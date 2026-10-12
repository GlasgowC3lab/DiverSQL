WITH sales_by_time AS (
    SELECT
        t.t_hour,
        t.t_shift,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 21
      AND t.t_shift = 'Evening'
    GROUP BY t.t_hour, t.t_shift
),
returns_by_time AS (
    SELECT
        t.t_hour,
        t.t_shift,
        SUM(wr.wr_net_loss) AS total_return_loss,
        SUM(wr.wr_return_quantity) AS total_quantity_returned,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_returns
    FROM web_returns wr
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 21
      AND t.t_shift = 'Evening'
    GROUP BY t.t_hour, t.t_shift
)
SELECT
    s.t_hour,
    s.t_shift,
    s.total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
    s.total_quantity_sold,
    COALESCE(r.total_quantity_returned, 0) AS total_quantity_returned,
    s.distinct_tickets,
    COALESCE(r.distinct_returns, 0) AS distinct_returns
FROM sales_by_time s
LEFT JOIN returns_by_time r
    ON s.t_hour = r.t_hour AND s.t_shift = r.t_shift
WHERE s.total_sales_profit > 1000
ORDER BY net_profit_after_returns DESC
LIMIT 50
