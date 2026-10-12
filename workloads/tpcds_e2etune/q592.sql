WITH sales AS (
  SELECT
    cs.cs_promo_sk,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales_amount,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
  FROM catalog_sales cs
  WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
  GROUP BY cs.cs_promo_sk
),
returns AS (
  SELECT
    cs.cs_promo_sk,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    SUM(cr.cr_net_loss) AS total_return_loss
  FROM catalog_returns cr
  JOIN catalog_sales cs
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
  WHERE cr.cr_refunded_addr_sk IN (2409583, 3405652)
    AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
  GROUP BY cs.cs_promo_sk
)
SELECT
  p.p_promo_name,
  p.p_purpose,
  s.total_sales_amount,
  s.total_sales_profit,
  COALESCE(r.total_return_amount, 0) AS total_return_amount,
  COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
  COALESCE(r.total_return_loss, 0) AS total_return_loss,
  (s.total_sales_profit - COALESCE(r.total_return_loss, 0)) AS net_profit_after_returns,
  CASE WHEN s.total_quantity_sold > 0
       THEN COALESCE(r.total_return_quantity, 0) * 1.0 / s.total_quantity_sold
       ELSE NULL END AS return_rate,
  RANK() OVER (ORDER BY (s.total_sales_profit - COALESCE(r.total_return_loss, 0)) DESC) AS profit_rank
FROM promotion p
JOIN sales s ON p.p_promo_sk = s.cs_promo_sk
LEFT JOIN returns r ON p.p_promo_sk = r.cs_promo_sk
WHERE p.p_start_date_sk BETWEEN 2450000 AND 2452000
  AND p.p_end_date_sk BETWEEN 2450000 AND 2452000
  AND p.p_purpose = 'Discount'
ORDER BY net_profit_after_returns DESC
LIMIT 10
