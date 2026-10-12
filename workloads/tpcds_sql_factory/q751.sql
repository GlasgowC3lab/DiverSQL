WITH store_profit_window AS (
    SELECT
        ss.ss_store_sk,
        td.t_hour,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        SUM(ss.ss_net_profit) OVER (PARTITION BY ss.ss_store_sk ORDER BY td.t_hour ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_store_sk ORDER BY td.t_hour) AS hour_seq
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE ss.ss_net_profit <> 0
)
SELECT
    spw.ss_store_sk,
    spw.t_hour,
    spw.cumulative_profit,
    spw.hour_seq,
    CASE WHEN spw.cumulative_profit > 0 THEN 'Positive' ELSE 'Negative' END AS profit_trend
FROM store_profit_window spw
WHERE spw.hour_seq % 2 = 0
ORDER BY spw.ss_store_sk, spw.t_hour
