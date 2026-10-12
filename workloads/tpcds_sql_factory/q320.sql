WITH store_profit_by_hour AS (
    SELECT
        ss.ss_store_sk,
        td.t_hour,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_ext_sales_price) AS avg_sales_price,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        MAX(ss.ss_net_profit) AS max_profit
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    GROUP BY ss.ss_store_sk, td.t_hour
    HAVING AVG(ss.ss_ext_sales_price) > 50
)
SELECT
    spb.ss_store_sk,
    spb.t_hour,
    spb.total_net_profit,
    spb.avg_sales_price,
    spb.total_discount,
    spb.max_profit,
    ROW_NUMBER() OVER (PARTITION BY spb.t_hour ORDER BY spb.max_profit DESC) AS max_profit_rank
FROM store_profit_by_hour spb
WHERE spb.total_discount > 0
ORDER BY spb.t_hour, max_profit_rank
