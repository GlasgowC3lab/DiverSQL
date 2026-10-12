WITH all_sales AS (
  SELECT cs.cs_sold_date_sk AS sold_date_sk,
         cs.cs_item_sk AS item_sk,
         cs.cs_quantity AS quantity,
         cs.cs_net_profit AS profit,
         cs.cs_bill_customer_sk AS customer_sk,
         cs.cs_promo_sk AS promo_sk
  FROM catalog_sales cs
  UNION ALL
  SELECT ss.ss_sold_date_sk,
         ss.ss_item_sk,
         ss.ss_quantity,
         ss.ss_net_profit,
         ss.ss_customer_sk,
         ss.ss_promo_sk
  FROM store_sales ss
  UNION ALL
  SELECT ws.ws_sold_date_sk,
         ws.ws_item_sk,
         ws.ws_quantity,
         ws.ws_net_profit,
         ws.ws_bill_customer_sk,
         ws.ws_promo_sk
  FROM web_sales ws
)
SELECT d.d_year,
       i.i_item_id,
       i.i_product_name,
       cd.cd_gender,
       SUM(s.quantity) AS total_quantity,
       SUM(s.profit) AS total_profit,
       AVG(s.profit) AS avg_profit_per_tx
FROM all_sales s
JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
JOIN customer c ON s.customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN promotion p ON s.promo_sk = p.p_promo_sk
WHERE d.d_year BETWEEN 2000 AND 2002
  AND cd.cd_gender = 'M'
  AND p.p_discount_active = 'Y'
GROUP BY d.d_year, i.i_item_id, i.i_product_name, cd.cd_gender
ORDER BY total_profit DESC
LIMIT 100
