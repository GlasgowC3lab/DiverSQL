WITH catalog AS (
  SELECT
    cs.cs_sold_date_sk AS sold_date_sk,
    i.i_category,
    ca.ca_country,
    cs.cs_net_profit AS net_profit,
    cs.cs_ext_discount_amt AS discount_amt,
    cs.cs_promo_sk AS promo_sk,
    cs.cs_quantity AS quantity,
    cs.cs_order_number AS order_id
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  WHERE ca.ca_country = 'United States'
    AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450150
),
store AS (
  SELECT
    ss.ss_sold_date_sk AS sold_date_sk,
    i.i_category,
    ca.ca_country,
    ss.ss_net_profit AS net_profit,
    ss.ss_ext_discount_amt AS discount_amt,
    ss.ss_promo_sk AS promo_sk,
    ss.ss_quantity AS quantity,
    ss.ss_ticket_number AS order_id
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE ca.ca_country = 'United States'
    AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450150
),
unified_sales AS (
  SELECT * FROM catalog
  UNION ALL
  SELECT * FROM store
)
SELECT
  i_category,
  sold_date_sk,
  SUM(net_profit) AS total_net_profit,
  AVG(discount_amt) AS avg_discount,
  COUNT(DISTINCT promo_sk) AS distinct_promotions,
  COUNT(*) AS total_transactions,
  RANK() OVER (ORDER BY SUM(net_profit) DESC) AS profit_rank
FROM unified_sales
GROUP BY i_category, sold_date_sk
ORDER BY total_net_profit DESC
LIMIT 50
