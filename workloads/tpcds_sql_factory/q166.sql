WITH returns_by_dept_state AS (
  SELECT
    cp.cp_department,
    ca.ca_state,
    SUM(cr.cr_net_loss) AS state_net_loss,
    SUM(cr.cr_return_amount) AS state_return_amount,
    COUNT(*) AS return_cnt,
    AVG(w.w_gmt_offset) AS avg_warehouse_gmt_offset
  FROM catalog_returns cr
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  GROUP BY cp.cp_department, ca.ca_state
),
dept_totals AS (
  SELECT
    cp_department,
    SUM(state_net_loss) AS dept_net_loss,
    SUM(state_return_amount) AS dept_return_amount
  FROM returns_by_dept_state
  GROUP BY cp_department
),
ranked AS (
  SELECT
    r.cp_department,
    r.ca_state,
    r.state_net_loss,
    r.state_return_amount,
    r.return_cnt,
    r.avg_warehouse_gmt_offset,
    DENSE_RANK() OVER (PARTITION BY r.cp_department ORDER BY r.state_net_loss DESC) AS state_rank,
    (r.state_net_loss / dt.dept_net_loss) * 100 AS net_loss_pct,
    (r.state_return_amount / dt.dept_return_amount) * 100 AS return_amount_pct
  FROM returns_by_dept_state r
  JOIN dept_totals dt ON r.cp_department = dt.cp_department
)
SELECT
  cp_department,
  ca_state,
  state_net_loss,
  state_return_amount,
  return_cnt,
  net_loss_pct,
  return_amount_pct,
  state_rank,
  CASE
    WHEN state_rank <= 3 THEN 'Top'
    ELSE 'Other'
  END AS rank_category,
  avg_warehouse_gmt_offset
FROM ranked
ORDER BY cp_department, state_rank
