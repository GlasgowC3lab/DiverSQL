WITH unified_sales AS (
 SELECT cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_bill_customer_sk AS cust_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_quantity AS quantity,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_net_profit AS net_profit,
        'catalog' AS sales_channel
 FROM catalog_sales cs
 UNION ALL
 SELECT ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit,
        'store'
 FROM store_sales ss
 UNION ALL
 SELECT ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_promo_sk,
        ws.ws_quantity,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        'web'
 FROM web_sales ws
),
sales_enriched AS (
 SELECT us.*,
        d.d_year,
        d.d_moy AS month_of_year,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        p.p_promo_name
 FROM unified_sales us
 LEFT JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
 LEFT JOIN customer c ON us.cust_sk = c.c_customer_sk
 LEFT JOIN item i ON us.item_sk = i.i_item_sk
 LEFT JOIN promotion p ON us.promo_sk = p.p_promo_sk
),
monthly_customer_profit AS (
 SELECT 
   d_year,
   month_of_year,
   sales_channel,
   c_customer_id,
   c_first_name,
   c_last_name,
   SUM(net_profit) AS total_net_profit,
   SUM(quantity) AS total_quantity,
   SUM(discount_amt) AS total_discount,
   SUM(discount_amt) / NULLIF(SUM(quantity), 0) AS avg_discount_per_item
 FROM sales_enriched
 WHERE d_year = 2002
 GROUP BY d_year, month_of_year, sales_channel, c_customer_id, c_first_name, c_last_name
),
customer_rank AS (
 SELECT 
   *,
   RANK() OVER (PARTITION BY d_year, sales_channel ORDER BY total_net_profit DESC) AS profit_rank,
   SUM(total_net_profit) OVER (PARTITION BY d_year, sales_channel) AS channel_total_profit,
   total_net_profit / SUM(total_net_profit) OVER (PARTITION BY d_year, sales_channel) AS profit_share
 FROM monthly_customer_profit
)
SELECT
  d_year,
  sales_channel,
  month_of_year,
  c_customer_id,
  c_first_name,
  c_last_name,
  total_quantity,
  total_net_profit,
  total_discount,
  avg_discount_per_item,
  profit_rank,
  profit_share
FROM customer_rank
WHERE profit_rank <= 10
ORDER BY d_year, sales_channel, profit_rank, month_of_year
