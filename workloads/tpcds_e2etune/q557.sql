WITH returns_combined AS (
  SELECT
    cr.cr_item_sk AS item_sk,
    cr.cr_ship_mode_sk AS ship_mode_sk,
    cr.cr_return_quantity AS return_quantity,
    cr.cr_net_loss AS net_loss,
    cr.cr_returned_time_sk AS time_sk,
    cr.cr_reason_sk AS reason_sk,
    cr.cr_order_number AS order_number,
    cr.cr_return_amount AS return_amount,
    'catalog' AS source
  FROM catalog_returns cr
  WHERE cr.cr_returned_date_sk BETWEEN 2451000 AND 2451100
    AND cr.cr_ship_mode_sk IN (7,12)
    AND cr.cr_return_amount > 0
  UNION ALL
  SELECT
    sr.sr_item_sk AS item_sk,
    NULL AS ship_mode_sk,
    sr.sr_return_quantity AS return_quantity,
    sr.sr_net_loss AS net_loss,
    sr.sr_return_time_sk AS time_sk,
    sr.sr_reason_sk AS reason_sk,
    NULL AS order_number,
    sr.sr_return_amt AS return_amount,
    'store' AS source
  FROM store_returns sr
  WHERE sr.sr_returned_date_sk BETWEEN 2451000 AND 2451100
    AND sr.sr_return_quantity > 0
),
agg AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    COALESCE(sm.sm_ship_mode_id, 'N/A') AS ship_mode_id,
    r.r_reason_desc,
    COUNT(*) AS return_events,
    SUM(rc.return_quantity) AS total_return_quantity,
    SUM(rc.net_loss) AS total_net_loss,
    AVG(rc.return_amount) AS avg_return_amount,
    SUM(cs.cs_net_profit) AS total_sales_net_profit,
    CASE WHEN SUM(cs.cs_net_profit) = 0 THEN NULL
         ELSE SUM(rc.net_loss) / SUM(cs.cs_net_profit) END AS loss_to_profit_ratio
  FROM returns_combined rc
  JOIN item i ON rc.item_sk = i.i_item_sk
  LEFT JOIN ship_mode sm ON rc.ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN reason r ON rc.reason_sk = r.r_reason_sk
  LEFT JOIN catalog_sales cs
    ON rc.source = 'catalog'
    AND rc.order_number = cs.cs_order_number
    AND rc.item_sk = cs.cs_item_sk
  WHERE r.r_reason_desc IS NOT NULL
  GROUP BY
    i.i_item_id,
    i.i_product_name,
    sm.sm_ship_mode_id,
    r.r_reason_desc
  HAVING SUM(rc.net_loss) > 1000
)
SELECT
  i_item_id,
  i_product_name,
  ship_mode_id,
  r_reason_desc,
  return_events,
  total_return_quantity,
  total_net_loss,
  avg_return_amount,
  total_sales_net_profit,
  loss_to_profit_ratio,
  RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 10
