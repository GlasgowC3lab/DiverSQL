WITH daily AS (
    SELECT ss_sold_date_sk AS date_sk,
           SUM(ss_net_profit) AS store_profit,
           SUM(ss_ext_discount_amt) AS store_discount,
           COUNT(DISTINCT ss_customer_sk) AS store_customers
    FROM store_sales
    GROUP BY ss_sold_date_sk
    UNION ALL
    SELECT ws_sold_date_sk,
           SUM(ws_net_profit),
           SUM(ws_ext_discount_amt),
           COUNT(DISTINCT ws_bill_customer_sk)
    FROM web_sales
    GROUP BY ws_sold_date_sk
),
agg AS (
    SELECT date_sk,
           SUM(store_profit) AS total_profit,
           SUM(store_discount) AS total_discount,
           SUM(store_customers) AS total_customers
    FROM daily
    GROUP BY date_sk
)
SELECT date_sk,
       total_profit,
       total_discount,
       total_customers,
       total_profit - total_discount AS net_after_discount,
       PERCENT_RANK() OVER (ORDER BY total_profit DESC) AS profit_percentile,
       CASE WHEN total_profit > LAG(total_profit, 1) OVER (ORDER BY date_sk) THEN 'Increase' ELSE 'Decrease' END AS profit_trend,
       (SELECT COUNT(*) FROM promotion p WHERE date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk) AS promos_active
FROM agg
WHERE total_customers > 50
ORDER BY total_profit ASC
LIMIT 100
