WITH monthly AS (
  SELECT
    CAST(cr.cr_returned_date_sk / 100 AS INTEGER) AS year_month,
    SUM(cr.cr_net_loss) AS month_net_loss,
    SUM(cr.cr_return_quantity) AS month_return_qty,
    SUM(cr.cr_return_amount) AS month_return_amount,
    COUNT(*) AS return_cnt,
    cp.cp_type,
    w.w_state,
    ca.ca_state AS refunded_state
  FROM catalog_returns cr
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  WHERE cp.cp_type = 'Seasonal'
    AND w.w_state = 'CA'
  GROUP BY CAST(cr.cr_returned_date_sk / 100 AS INTEGER), cp.cp_type, w.w_state, ca.ca_state
),
trend AS (
  SELECT
    m.year_month,
    m.month_net_loss,
    m.month_return_qty,
    m.month_return_amount,
    m.return_cnt,
    m.refunded_state,
    SUM(m.month_net_loss) OVER (ORDER BY m.year_month) AS cumulative_net_loss,
    LAG(m.month_net_loss) OVER (ORDER BY m.year_month) AS prev_month_net_loss,
    CASE
      WHEN LAG(m.month_net_loss) OVER (ORDER BY m.year_month) IS NULL THEN 'N/A'
      WHEN m.month_net_loss > LAG(m.month_net_loss) OVER (ORDER BY m.year_month) * 1.10 THEN 'Spike'
      ELSE 'Normal'
    END AS net_loss_change_flag
  FROM monthly m
)
SELECT
  year_month,
  month_net_loss,
  month_return_qty,
  month_return_amount,
  return_cnt,
  refunded_state,
  cumulative_net_loss,
  prev_month_net_loss,
  net_loss_change_flag
FROM trend
ORDER BY year_month
