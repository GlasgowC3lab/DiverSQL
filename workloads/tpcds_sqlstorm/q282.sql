WITH date_range AS (
   SELECT d_date_sk
   FROM date_dim
   WHERE d_year = 2000
),
store_sales_agg AS (
   SELECT ss_customer_sk,
          SUM(ss_net_profit) AS store_net_profit,
          SUM(ss_ext_discount_amt) AS store_discount,
          COUNT(*) AS store_transactions,
          MAX(d_date) AS last_sale_date
   FROM store_sales ss
   JOIN date_range dr ON ss.ss_sold_date_sk = dr.d_date_sk
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   GROUP BY ss_customer_sk
),
catalog_sales_agg AS (
   SELECT cs_bill_customer_sk AS cust_sk,
          SUM(cs_net_profit) AS catalog_net_profit,
          SUM(cs_ext_discount_amt) AS catalog_discount,
          COUNT(*) AS catalog_transactions,
          MAX(d_date) AS last_sale_date
   FROM catalog_sales cs
   JOIN date_range dr ON cs.cs_sold_date_sk = dr.d_date_sk
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   GROUP BY cs_bill_customer_sk
),
web_sales_agg AS (
   SELECT ws_bill_customer_sk AS cust_sk,
          SUM(ws_net_profit) AS web_net_profit,
          SUM(ws_ext_discount_amt) AS web_discount,
          COUNT(*) AS web_transactions,
          MAX(d_date) AS last_sale_date
   FROM web_sales ws
   JOIN date_range dr ON ws.ws_sold_date_sk = dr.d_date_sk
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   GROUP BY ws_bill_customer_sk
),
customer_info AS (
   SELECT c.c_customer_sk,
          concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
          c.c_preferred_cust_flag,
          coalesce(c.c_birth_country, 'UNKNOWN') AS birth_country
   FROM customer c
),
combined AS (
   SELECT ci.c_customer_sk,
          ci.full_name,
          COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0) AS total_net_profit,
          COALESCE(ss.store_discount, 0) + COALESCE(cs.catalog_discount, 0) + COALESCE(ws.web_discount, 0) AS total_discount,
          GREATEST(COALESCE(ss.store_transactions,0), COALESCE(cs.catalog_transactions,0), COALESCE(ws.web_transactions,0)) AS max_transactions,
          COALESCE(ss.last_sale_date, cs.last_sale_date, ws.last_sale_date) AS last_sale_date,
          ci.c_preferred_cust_flag,
          ci.birth_country,
          (SELECT AVG(ss2.ss_net_profit)
           FROM store_sales ss2
           WHERE ss2.ss_customer_sk = ci.c_customer_sk
             AND ss2.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2000)
          ) AS avg_store_profit_2000
   FROM customer_info ci
   LEFT JOIN store_sales_agg ss ON ci.c_customer_sk = ss.ss_customer_sk
   LEFT JOIN catalog_sales_agg cs ON ci.c_customer_sk = cs.cust_sk
   LEFT JOIN web_sales_agg ws ON ci.c_customer_sk = ws.cust_sk
   WHERE (COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0)) > 0
),
ranked AS (
   SELECT *,
          ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
          RANK() OVER (PARTITION BY c_preferred_cust_flag ORDER BY total_net_profit DESC) AS flag_rank
   FROM combined
)
SELECT profit_rank,
       c_customer_sk,
       full_name,
       total_net_profit,
       total_discount,
       max_transactions,
       last_sale_date,
       c_preferred_cust_flag,
       birth_country,
       avg_store_profit_2000,
       CASE
          WHEN total_net_profit > 10000 THEN 'HIGH'
          WHEN total_net_profit BETWEEN 1000 AND 10000 THEN 'MEDIUM'
          ELSE 'LOW'
       END AS profit_category
FROM ranked
WHERE profit_rank <= 10
UNION ALL
SELECT NULL AS profit_rank,
       NULL AS c_customer_sk,
       concat('Summary for year ', CAST(2000 AS VARCHAR)) AS full_name,
       SUM(total_net_profit) AS total_net_profit,
       SUM(total_discount) AS total_discount,
       SUM(max_transactions) AS max_transactions,
       NULL AS last_sale_date,
       NULL AS c_preferred_cust_flag,
       NULL AS birth_country,
       NULL AS avg_store_profit_2000,
       NULL AS profit_category
FROM ranked
WHERE profit_rank <= 10
ORDER BY profit_rank NULLS LAST, total_net_profit DESC
