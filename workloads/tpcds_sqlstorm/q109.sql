WITH sales AS (
   SELECT ss_customer_sk AS customer_sk,
          ss_net_profit AS net_profit,
          d.d_year
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   UNION ALL
   SELECT cs_bill_customer_sk AS customer_sk,
          cs_net_profit AS net_profit,
          d.d_year
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   UNION ALL
   SELECT ws_bill_customer_sk AS customer_sk,
          ws_net_profit AS net_profit,
          d.d_year
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
), customer_profit AS (
   SELECT c.c_customer_id,
          c.c_first_name,
          c.c_last_name,
          s.d_year,
          SUM(s.net_profit) AS total_net_profit
   FROM sales s
   JOIN customer c ON s.customer_sk = c.c_customer_sk
   WHERE s.d_year = 2000
   GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, s.d_year
), ranked AS (
   SELECT *,
          ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS rn
   FROM customer_profit
)
SELECT c_customer_id,
       c_first_name,
       c_last_name,
       d_year,
       total_net_profit
FROM ranked
WHERE rn <= 10
ORDER BY total_net_profit DESC
