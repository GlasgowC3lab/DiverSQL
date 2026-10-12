WITH daily_store AS (
    SELECT ss_sold_date_sk AS date_sk,
           SUM(ss_net_profit) AS store_net_profit,
           COUNT(DISTINCT ss_customer_sk) AS store_customer_cnt
    FROM store_sales
    GROUP BY ss_sold_date_sk
),
 daily_web AS (
    SELECT ws_sold_date_sk AS date_sk,
           SUM(ws_net_profit) AS web_net_profit,
           COUNT(DISTINCT ws_bill_customer_sk) AS web_customer_cnt
    FROM web_sales
    GROUP BY ws_sold_date_sk
),
 daily_combined AS (
    SELECT COALESCE(ds.date_sk, dw.date_sk) AS date_sk,
           COALESCE(ds.store_net_profit, 0) AS store_net_profit,
           COALESCE(dw.web_net_profit, 0) AS web_net_profit,
           COALESCE(ds.store_customer_cnt, 0) + COALESCE(dw.web_customer_cnt, 0) AS total_customer_cnt,
           COALESCE(ds.store_net_profit, 0) + COALESCE(dw.web_net_profit, 0) AS total_net_profit
    FROM daily_store ds
    FULL OUTER JOIN daily_web dw ON ds.date_sk = dw.date_sk
)
SELECT
    date_sk,
    store_net_profit,
    web_net_profit,
    total_customer_cnt,
    total_net_profit,
    moving_avg_7d,
    CASE WHEN total_net_profit >= moving_avg_7d THEN 'Above Avg' ELSE 'Below Avg' END AS profit_vs_mavg,
    profit_rank,
    active_promo_cnt
FROM (
    SELECT
        dc.date_sk,
        dc.store_net_profit,
        dc.web_net_profit,
        dc.total_customer_cnt,
        dc.total_net_profit,
        AVG(dc.total_net_profit) OVER (ORDER BY dc.date_sk ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7d,
        RANK() OVER (ORDER BY dc.total_net_profit DESC) AS profit_rank,
        (SELECT COUNT(*) FROM promotion p WHERE dc.date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk) AS active_promo_cnt
    FROM daily_combined dc
) t
ORDER BY date_sk
LIMIT 200
