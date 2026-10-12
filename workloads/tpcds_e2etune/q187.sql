WITH daily_current AS (
    SELECT d.d_date_sk,
           d.d_day_name,
           SUM(ss.ss_net_profit) AS profit_current
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_current_year = 'Y'
    GROUP BY d.d_date_sk, d.d_day_name
),

daily_prev AS (
    SELECT d.d_date_sk,
           SUM(ss.ss_net_profit) AS profit_prev
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk
),

joined AS (
    SELECT dc.d_day_name,
           dc.profit_current,
           dp.profit_prev
    FROM daily_current dc
    JOIN date_dim dmap ON dc.d_date_sk = dmap.d_date_sk
    JOIN daily_prev dp ON dmap.d_same_day_lq = dp.d_date_sk
    WHERE dmap.d_same_day_lq IS NOT NULL
)
SELECT d_day_name,
       SUM(profit_current) AS total_current_profit,
       SUM(profit_prev) AS total_prev_profit,
       CASE WHEN SUM(profit_prev) = 0 THEN NULL
            ELSE (SUM(profit_current) - SUM(profit_prev)) / SUM(profit_prev)
       END AS profit_growth_ratio,
       RANK() OVER (ORDER BY CASE WHEN SUM(profit_prev) = 0 THEN NULL
                                 ELSE (SUM(profit_current) - SUM(profit_prev)) / SUM(profit_prev)
                            END DESC) AS growth_rank
FROM joined
GROUP BY d_day_name
HAVING SUM(profit_current) > 0
ORDER BY growth_rank
LIMIT 5
