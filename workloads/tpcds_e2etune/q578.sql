WITH aggregated AS (
  SELECT
    ca_ret.ca_state AS returning_state,
    ca_ref.ca_state AS refunded_state,
    cr.cr_ship_mode_sk AS ship_mode,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_net_loss) / NULLIF(COUNT(DISTINCT cr.cr_order_number), 0) AS net_loss_per_order
  FROM catalog_returns cr
  JOIN customer_address ca_ret
    ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
  JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
  WHERE cr.cr_return_tax > 10.0
    AND cr.cr_ship_mode_sk IN (4, 9, 16)
  GROUP BY ca_ret.ca_state, ca_ref.ca_state, cr.cr_ship_mode_sk
  HAVING SUM(cr.cr_return_amount) > 1000
)
SELECT
  returning_state,
  refunded_state,
  ship_mode,
  total_return_amount,
  total_net_loss,
  avg_return_tax,
  total_return_quantity,
  distinct_orders,
  net_loss_per_order,
  RANK() OVER (PARTITION BY returning_state ORDER BY total_net_loss DESC) AS net_loss_rank
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 100
