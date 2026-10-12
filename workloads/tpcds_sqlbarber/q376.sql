SELECT
  cs.cs_sold_date_sk,
  c.c_customer_id,
  p.p_promo_name,
  SUM(cs.cs_net_paid) AS total_net_paid,
  COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
FROM catalog_sales cs
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
WHERE cs.cs_sold_date_sk BETWEEN 2450816 AND 2450816
  AND p.p_discount_active = 'N'
GROUP BY
  cs.cs_sold_date_sk,
  c.c_customer_id,
  p.p_promo_name
ORDER BY total_net_paid DESC
LIMIT 1000
