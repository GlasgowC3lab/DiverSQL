WITH cat_items AS (
   SELECT DISTINCT cs.cs_item_sk
   FROM catalog_sales cs
   TABLESAMPLE BERNOULLI (5)
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE regexp_like(i.i_item_desc, '(?i)wireless')
     AND i.i_product_name LIKE '%Plus%'
),
web_items AS (
   SELECT DISTINCT ws.ws_item_sk
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE regexp_like(i.i_item_desc, '(?i)wireless')
     AND i.i_product_name LIKE '%Plus%'
),
common_items AS (
   SELECT cs_item_sk AS item_sk FROM cat_items
   INTERSECT
   SELECT ws_item_sk FROM web_items
),
sales_agg AS (
   SELECT
       ci.item_sk,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       SUM(cs.cs_net_profit)                         AS cat_profit,
       SUM(ws.ws_net_profit)                         AS web_profit,
       COUNT(DISTINCT cs.cs_bill_customer_sk)        AS cat_customers,
       COUNT(DISTINCT ws.ws_bill_customer_sk)        AS web_customers,
       MAX(substring(i.i_product_name, 1, 10))      AS product_name_prefix
   FROM common_items ci
   LEFT JOIN catalog_sales cs ON cs.cs_item_sk = ci.item_sk
   LEFT JOIN web_sales ws     ON ws.ws_item_sk   = ci.item_sk
   LEFT JOIN customer c      ON cs.cs_bill_customer_sk = c.c_customer_sk
   LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
   LEFT JOIN income_band ib  ON hd.hd_income_band_sk = ib.ib_income_band_sk
   LEFT JOIN item i          ON i.i_item_sk = ci.item_sk
   GROUP BY ci.item_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
   ib_lower_bound,
   ib_upper_bound,
   cat_profit,
   web_profit,
   cat_customers + web_customers                     AS total_customers,
   product_name_prefix,
   CASE WHEN cat_profit + web_profit > 15000 THEN 'High' ELSE 'Low' END AS profit_category
FROM sales_agg
ORDER BY cat_profit DESC
LIMIT 20
