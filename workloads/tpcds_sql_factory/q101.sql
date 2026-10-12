WITH store_profit_by_hour AS (
    SELECT
        ss.ss_store_sk,
        td.t_hour,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 0
             THEN SUM(ss.ss_ext_discount_amt) / SUM(ss.ss_ext_sales_price)
             ELSE 0 END AS discount_rate
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    GROUP BY ss.ss_store_sk, td.t_hour
    HAVING SUM(ss.ss_net_profit) > 0
)
SELECT
    spb.ss_store_sk,
    spb.t_hour,
    spb.total_net_profit,
    spb.total_sales,
    spb.total_discount,
    spb.discount_rate,
    RANK() OVER (PARTITION BY spb.t_hour ORDER BY spb.total_net_profit DESC) AS profit_rank_per_hour
FROM store_profit_by_hour spb
ORDER BY spb.t_hour, profit_rank_per_hour
