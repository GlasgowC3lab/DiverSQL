WITH hourly_sales AS (
    SELECT
        t.t_hour,
        SUM(s.ss_net_profit) AS total_net_profit,
        COUNT(*) AS txn_count
    FROM store_sales s
    JOIN time_dim t ON s.ss_sold_time_sk = t.t_time_sk
    WHERE s.ss_ext_list_price > 1000.00
    GROUP BY t.t_hour
),
union_hours AS (
    SELECT
        h.t_hour,
        h.total_net_profit,
        h.txn_count
    FROM hourly_sales h
    WHERE h.t_hour BETWEEN 6 AND 11

    UNION ALL

    SELECT
        h.t_hour,
        h.total_net_profit,
        h.txn_count
    FROM hourly_sales h
    WHERE h.t_hour BETWEEN 12 AND 17
)
SELECT
    u.t_hour,
    u.total_net_profit,
    u.txn_count
FROM union_hours u
WHERE EXISTS (
    SELECT 1
    FROM store_sales s2
    JOIN time_dim t2 ON s2.ss_sold_time_sk = t2.t_time_sk
    WHERE t2.t_hour = u.t_hour
      AND s2.ss_coupon_amt > 500.00
)
ORDER BY u.total_net_profit DESC, u.t_hour ASC
LIMIT 100
