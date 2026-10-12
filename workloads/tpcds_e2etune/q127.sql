SELECT p.p_promo_name,
       td_sales.t_hour AS sales_hour,
       SUM(cs.cs_net_paid_inc_tax) AS total_sales,
       SUM(cr.cr_net_loss) AS total_return_loss,
       COUNT(DISTINCT cr.cr_order_number) AS num_returns,
       AVG(cs.cs_ext_discount_amt) AS avg_discount
FROM catalog_sales cs
JOIN catalog_returns cr
  ON cs.cs_item_sk = cr.cr_item_sk
 AND cs.cs_order_number = cr.cr_order_number
JOIN time_dim td_sales
  ON cs.cs_sold_time_sk = td_sales.t_time_sk
JOIN time_dim td_returns
  ON cr.cr_returned_time_sk = td_returns.t_time_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
WHERE cr.cr_warehouse_sk = 9
  AND p.p_channel_tv = 'Y'
  AND td_sales.t_hour BETWEEN 9 AND 17
GROUP BY p.p_promo_name, td_sales.t_hour
HAVING SUM(cs.cs_net_paid_inc_tax) > 10000
ORDER BY total_sales DESC
LIMIT 100
