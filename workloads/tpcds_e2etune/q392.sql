WITH profit_agg AS (
    SELECT
        t.t_hour,
        hd.hd_vehicle_count,
        hd.hd_income_band_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        GROUPING(t.t_hour) AS g_hour,
        GROUPING(hd.hd_vehicle_count) AS g_vehicle,
        GROUPING(hd.hd_income_band_sk) AS g_income_band
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE t.t_hour BETWEEN 12 AND 23
      AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2450996
    GROUP BY GROUPING SETS (
        (t.t_hour, hd.hd_vehicle_count, hd.hd_income_band_sk),
        (t.t_hour, hd.hd_vehicle_count),
        (t.t_hour),
        ()
    )
    HAVING SUM(ss.ss_net_profit) > 1000
)
SELECT
    pa.t_hour,
    pa.hd_vehicle_count,
    pa.hd_income_band_sk,
    pa.total_net_profit,
    pa.distinct_customers,
    CASE 
        WHEN pa.total_net_profit >= 50000 THEN 'High'
        WHEN pa.total_net_profit >= 20000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY pa.t_hour ORDER BY pa.total_net_profit DESC) AS rank_within_hour
FROM profit_agg pa
ORDER BY pa.total_net_profit DESC
LIMIT 200
