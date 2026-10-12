WITH all_sales AS (
  SELECT ss.ss_customer_sk AS cust_sk, ss.ss_net_profit AS profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
  UNION ALL
  SELECT cs.cs_bill_customer_sk AS cust_sk, cs.cs_net_profit AS profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
  UNION ALL
  SELECT ws.ws_bill_customer_sk AS cust_sk, ws.ws_net_profit AS profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
)
SELECT c.c_customer_id,
       sum(a.profit) AS total_profit
FROM all_sales a
JOIN customer c ON a.cust_sk = c.c_customer_sk
GROUP BY c.c_customer_id
ORDER BY total_profit DESC
LIMIT 10
