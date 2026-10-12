WITH RECURSIVE hours (hour) AS (
    SELECT 0
    UNION ALL
    SELECT hour + 1 FROM hours WHERE hour < 23
)
SELECT store_sk,
       hour,
       total_net_profit,
       sales_cnt
FROM (
    SELECT ss.ss_store_sk AS store_sk,
           td.t_hour AS hour,
           SUM(ss.ss_net_profit) AS total_net_profit,
           COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN hours h ON td.t_hour = h.hour
    WHERE td.t_shift = 'MORNING'
      AND ss.ss_coupon_amt > 200
      AND NOT EXISTS (
            SELECT 1
            FROM store_sales ss2
            WHERE ss2.ss_store_sk = ss.ss_store_sk
              AND ss2.ss_sold_date_sk = ss.ss_sold_date_sk
              AND ss2.ss_net_profit > ss.ss_net_profit
      )
    GROUP BY ss.ss_store_sk, td.t_hour
    HAVING SUM(ss.ss_net_profit) > 15000
    UNION ALL
    SELECT ss.ss_store_sk AS store_sk,
           td.t_hour AS hour,
           SUM(ss.ss_net_profit) AS total_net_profit,
           COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN hours h ON td.t_hour = h.hour
    WHERE td.t_shift = 'EVENING'
      AND ss.ss_coupon_amt BETWEEN 50 AND 150
      AND NOT EXISTS (
            SELECT 1
            FROM store_sales ss2
            WHERE ss2.ss_store_sk = ss.ss_store_sk
              AND ss2.ss_sold_date_sk = ss.ss_sold_date_sk
              AND ss2.ss_net_profit > ss.ss_net_profit
      )
    GROUP BY ss.ss_store_sk, td.t_hour
    HAVING SUM(ss.ss_net_profit) > 12000
) AS combined
ORDER BY total_net_profit DESC
LIMIT 100
