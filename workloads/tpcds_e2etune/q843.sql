SELECT p.p_promo_name,
       wp.wp_type,
       COUNT(cr.cr_order_number) AS num_returns,
       SUM(cr.cr_net_loss) AS total_net_loss,
       AVG(cr.cr_net_loss) AS avg_net_loss,
       SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
       SUM(cr.cr_fee) AS total_fees,
       SUM(cr.cr_return_tax) AS total_tax,
       SUM(cr.cr_return_quantity) AS total_quantity,
       ROUND(SUM(cr.cr_return_amt_inc_tax) / NULLIF(COUNT(cr.cr_order_number), 0), 2) AS avg_return_amount,
       MIN(cr.cr_returned_date_sk) AS earliest_return_date_sk,
       MAX(cr.cr_returned_date_sk) AS latest_return_date_sk
FROM catalog_returns cr
JOIN promotion p
  ON cr.cr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
JOIN web_page wp
  ON cr.cr_returned_date_sk = wp.wp_creation_date_sk
WHERE p.p_discount_active = 'Y'
  AND wp.wp_type IN ('home', 'product', 'search')
  AND cr.cr_return_amount > 0
GROUP BY p.p_promo_name, wp.wp_type
HAVING COUNT(cr.cr_order_number) >= 10
ORDER BY total_net_loss DESC
LIMIT 50
