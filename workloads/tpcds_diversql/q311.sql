SELECT 
  cr.cr_order_number,
  SUM(cs.cs_net_profit) AS total_net_profit,
  AVG(cr.cr_return_amt_inc_tax) AS avg_return_inc_tax
FROM catalog_returns AS cr
JOIN catalog_sales AS cs
  ON cr.cr_item_sk = cs.cs_item_sk
 AND cr.cr_order_number = cs.cs_order_number
WHERE cr.cr_return_amt_inc_tax > 500
  AND cs.cs_coupon_amt = 0.00
GROUP BY cr.cr_order_number
ORDER BY total_net_profit DESC
LIMIT 10
