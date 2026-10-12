WITH unified_sales AS (
  SELECT cs.cs_sold_date_sk AS date_sk,
         cs.cs_item_sk AS item_sk,
         cs.cs_promo_sk AS promo_sk,
         cs.cs_quantity AS quantity,
         cs.cs_ext_sales_price AS sales_amount,
         cs.cs_net_profit AS profit_amount,
         cs.cs_bill_customer_sk AS customer_sk
  FROM catalog_sales cs
  UNION ALL
  SELECT ss.ss_sold_date_sk,
         ss.ss_item_sk,
         ss.ss_promo_sk,
         ss.ss_quantity,
         ss.ss_ext_sales_price,
         ss.ss_net_profit,
         ss.ss_customer_sk
  FROM store_sales ss
  UNION ALL
  SELECT ws.ws_sold_date_sk,
         ws.ws_item_sk,
         ws.ws_promo_sk,
         ws.ws_quantity,
         ws.ws_ext_sales_price,
         ws.ws_net_profit,
         ws.ws_bill_customer_sk
  FROM web_sales ws
),
pre_join AS (
  SELECT us.date_sk,
         us.item_sk,
         us.promo_sk,
         us.quantity,
         us.sales_amount,
         us.profit_amount,
         us.customer_sk,
         d.d_year,
         i.i_category,
         i.i_brand,
         p.p_promo_name,
         p.p_discount_active
  FROM unified_sales us
  JOIN date_dim d ON us.date_sk = d.d_date_sk
  JOIN item i ON us.item_sk = i.i_item_sk
  LEFT JOIN promotion p ON us.promo_sk = p.p_promo_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
    AND (p.p_discount_active IS NULL OR p.p_discount_active = 'Y')
),
agg_sales AS (
  SELECT d_year,
         i_category,
         i_brand,
         SUM(sales_amount) AS total_sales,
         SUM(profit_amount) AS total_profit,
         COUNT(DISTINCT customer_sk) AS distinct_customers
  FROM pre_join
  GROUP BY d_year, i_category, i_brand
  HAVING SUM(sales_amount) > 1000000
)
SELECT
  d_year,
  i_category,
  i_brand,
  total_sales,
  total_profit,
  distinct_customers,
  AVG(total_sales) OVER (PARTITION BY d_year) AS avg_sales_per_year,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM agg_sales
ORDER BY total_sales DESC
LIMIT 100
