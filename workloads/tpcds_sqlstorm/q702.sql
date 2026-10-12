WITH combined_sales AS (
  SELECT ss_sold_date_sk AS date_sk,
         ss_store_sk AS store_sk,
         ss_item_sk AS item_sk,
         ss_net_paid AS net_paid,
         ss_net_profit AS net_profit,
         ss_ext_discount_amt AS discount_amt,
         'store' AS channel
  FROM store_sales
  UNION ALL
  SELECT cs_sold_date_sk,
         cs_call_center_sk,
         cs_item_sk,
         cs_net_paid,
         cs_net_profit,
         cs_ext_discount_amt,
         'catalog'
  FROM catalog_sales
  UNION ALL
  SELECT ws_sold_date_sk,
         ws_warehouse_sk,
         ws_item_sk,
         ws_net_paid,
         ws_net_profit,
         ws_ext_discount_amt,
         'web'
  FROM web_sales
)
SELECT d.d_year,
       s.channel,
       i.i_category,
       SUM(s.net_paid) AS total_net_paid,
       SUM(s.net_profit) AS total_net_profit,
       AVG(s.discount_amt) AS avg_discount,
       COUNT(1) AS sales_cnt
FROM combined_sales s
JOIN date_dim d ON s.date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, s.channel, i.i_category
ORDER BY total_net_profit DESC
LIMIT 100
