WITH all_sales AS (
   SELECT cs_sold_date_sk AS date_sk, cs_bill_customer_sk AS cust_sk, cs_net_profit AS profit, 'catalog' AS channel
   FROM catalog_sales
   UNION ALL
   SELECT ss_sold_date_sk, ss_customer_sk, ss_net_profit, 'store'
   FROM store_sales
   UNION ALL
   SELECT ws_sold_date_sk, ws_bill_customer_sk, ws_net_profit, 'web'
   FROM web_sales
),
sales_with_date AS (
   SELECT a.channel, d.d_year, c.c_customer_id, a.profit
   FROM all_sales a
   JOIN date_dim d ON a.date_sk = d.d_date_sk
   JOIN customer c ON a.cust_sk = c.c_customer_sk
),
agg AS (
   SELECT channel, d_year, c_customer_id, SUM(profit) AS total_profit
   FROM sales_with_date
   GROUP BY channel, d_year, c_customer_id
)
SELECT channel, d_year, c_customer_id, total_profit
FROM agg
WHERE total_profit > (SELECT AVG(total_profit) FROM agg)
ORDER BY total_profit DESC
LIMIT 100
