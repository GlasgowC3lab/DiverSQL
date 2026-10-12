WITH daily_metrics AS (
    SELECT ss_sold_date_sk AS date_sk,
           SUM(ss_net_profit) AS profit,
           AVG(ss_ext_discount_amt) AS avg_discount,
           COUNT(DISTINCT ss_customer_sk) AS cust_cnt
    FROM store_sales
    WHERE ss_ext_wholesale_cost IS NOT NULL
    GROUP BY ss_sold_date_sk
    UNION ALL
    SELECT ws_sold_date_sk,
           SUM(ws_net_profit),
           AVG(ws_ext_discount_amt),
           COUNT(DISTINCT ws_bill_customer_sk)
    FROM web_sales
    WHERE ws_ext_wholesale_cost IS NOT NULL
    GROUP BY ws_sold_date_sk
),
summary AS (
    SELECT date_sk,
           SUM(profit) AS total_profit,
           AVG(avg_discount) AS overall_avg_discount,
           SUM(cust_cnt) AS total_customers
    FROM daily_metrics
    GROUP BY date_sk
)
SELECT date_sk,
       total_profit,
       overall_avg_discount,
       total_customers,
       total_profit * overall_avg_discount AS discount_impact,
       ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS profit_rank,
       CASE WHEN total_profit > (SELECT AVG(total_profit) FROM summary) THEN 'Above Mean' ELSE 'Below Mean' END AS profit_vs_mean,
       (SELECT COUNT(*) FROM promotion p WHERE date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk) AS promos_active
FROM summary
WHERE total_customers BETWEEN 20 AND 500
ORDER BY date_sk
LIMIT 120
