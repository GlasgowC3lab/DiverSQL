WITH sales_hourly AS (
    SELECT
        td.t_hour,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    GROUP BY td.t_hour
),
returns_hourly AS (
    SELECT
        td.t_hour,
        SUM(cr.cr_net_loss) AS total_loss,
        COUNT(*) AS returns_cnt
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    GROUP BY td.t_hour
)
SELECT
    COALESCE(s.t_hour, r.t_hour) AS hour_of_day,
    COALESCE(s.total_profit, 0) AS profit,
    COALESCE(r.total_loss, 0) AS loss,
    (COALESCE(s.total_profit, 0) - COALESCE(r.total_loss, 0)) AS net_contribution,
    CASE
        WHEN (COALESCE(s.total_profit, 0) - COALESCE(r.total_loss, 0)) >= 50000 THEN 'HIGH'
        WHEN (COALESCE(s.total_profit, 0) - COALESCE(r.total_loss, 0)) >= 20000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS contribution_category,
    DENSE_RANK() OVER (ORDER BY (COALESCE(s.total_profit, 0) - COALESCE(r.total_loss, 0)) DESC) AS profit_rank
FROM sales_hourly s
FULL OUTER JOIN returns_hourly r ON s.t_hour = r.t_hour
ORDER BY net_contribution DESC
