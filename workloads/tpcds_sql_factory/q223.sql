WITH returns_by_dept_state AS (
  SELECT
    cp.cp_department,
    ca.ca_state,
    SUM(cr.cr_net_loss) AS state_net_loss,
    SUM(cr.cr_return_amount) AS state_return_amount,
    COUNT(*) AS return_cnt,
    MAX(w.w_gmt_offset) AS max_warehouse_gmt_offset
  FROM catalog_returns cr
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  WHERE cr.cr_returned_date_sk >= 20000101  -- filter recent returns
  GROUP BY cp.cp_department, ca.ca_state
),
dept_totals AS (
  SELECT
    cp_department,
    SUM(state_net_loss) AS dept_net_loss,
    SUM(state_return_amount) AS dept_return_amount,
    COUNT(*) AS dept_state_cnt
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
    r.max_warehouse_gmt_offset,
    DENSE_RANK() OVER (PARTITION BY r.cp_department ORDER BY r.state_return_amount DESC) AS state_rank,
    (r.state_net_loss / dt.dept_net_loss) * 100 AS net_loss_pct,
    (r.state_return_amount / dt.dept_return_amount) * 100 AS return_amount_pct,
    ROW_NUMBER() OVER (PARTITION BY r.cp_department ORDER BY r.return_cnt DESC) AS return_cnt_rank
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
  CASE WHEN state_rank <= 5 THEN 'Top5' ELSE 'Other' END AS rank_category,
  max_warehouse_gmt_offset
FROM ranked
WHERE return_cnt_rank <= 10
ORDER BY cp_department, state_rank
