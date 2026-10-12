SELECT
  p.p_promo_name AS promo_name,
  cc.cc_city AS call_center_city,
  SUM(s.cs_net_profit) AS total_net_profit,
  SUM(s.cs_quantity) AS total_quantity_sold,
  COALESCE(SUM(r.cr_return_quantity), 0) AS total_quantity_returned,
  SUM(s.cs_net_profit) - COALESCE(SUM(r.cr_return_amount), 0) AS net_profit_after_returns,
  AVG(s.cs_ext_discount_amt) AS avg_discount_amount,
  COUNT(DISTINCT s.cs_order_number) AS distinct_orders
FROM catalog_sales s
JOIN call_center cc
  ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p
  ON s.cs_promo_sk = p.p_promo_sk
JOIN household_demographics hd
  ON s.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN catalog_returns r
  ON s.cs_order_number = r.cr_order_number
WHERE cc.cc_tax_percentage >= 0.05
  AND cc.cc_rec_start_date >= DATE '2000-01-01'
  AND p.p_start_date_sk >= 2451545
  AND s.cs_quantity > 0
GROUP BY p.p_promo_name, cc.cc_city
HAVING SUM(s.cs_net_profit) > 10000
ORDER BY net_profit_after_returns DESC
LIMIT 50
