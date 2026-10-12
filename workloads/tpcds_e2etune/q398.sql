SELECT
  sm_type,
  sm_carrier,
  i_category,
  i_brand,
  return_cnt,
  total_net_loss,
  avg_return_amount,
  total_store_credit,
  RANK() OVER (PARTITION BY i_category ORDER BY total_net_loss DESC) AS net_loss_rank
FROM (
  SELECT
    sm.sm_type AS sm_type,
    sm.sm_carrier AS sm_carrier,
    i.i_category AS i_category,
    i.i_brand AS i_brand,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(cr.cr_store_credit) AS total_store_credit
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE cr.cr_return_tax > 30
    AND cr.cr_return_quantity > 1
    AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2452000
  GROUP BY sm.sm_type, sm.sm_carrier, i.i_category, i.i_brand
  HAVING SUM(cr.cr_net_loss) > 1000
) agg
ORDER BY total_net_loss DESC
LIMIT 100
