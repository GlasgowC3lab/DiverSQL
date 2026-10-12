WITH return_agg AS (
  SELECT
    cp.cp_catalog_page_sk,
    cp.cp_department,
    cp.cp_catalog_page_number,
    cp.cp_type,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    COUNT(DISTINCT cr.cr_warehouse_sk) AS warehouse_cnt,
    AVG(cr.cr_net_loss) AS avg_net_loss
  FROM catalog_returns cr
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  GROUP BY cp.cp_catalog_page_sk, cp.cp_department, cp.cp_catalog_page_number, cp.cp_type
),
ranked AS (
  SELECT
    ra.*, 
    RANK() OVER (ORDER BY ra.total_net_loss DESC) AS loss_rank
  FROM return_agg ra
)
SELECT
  r.cp_department,
  r.cp_catalog_page_number,
  r.cp_type,
  r.total_net_loss,
  r.total_return_qty,
  r.warehouse_cnt,
  r.avg_net_loss,
  CASE
    WHEN r.avg_net_loss > 100 THEN 'High'
    WHEN r.avg_net_loss > 50 THEN 'Medium'
    ELSE 'Low'
  END AS loss_severity,
  r.loss_rank,
  MIN(w.w_city) AS example_warehouse_city,
  MIN(w.w_state) AS example_warehouse_state,
  MIN(ca.ca_state) AS example_refunded_state
FROM ranked r
LEFT JOIN catalog_returns cr ON cr.cr_catalog_page_sk = r.cp_catalog_page_sk
LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
WHERE r.loss_rank <= 10
GROUP BY r.cp_department, r.cp_catalog_page_number, r.cp_type, r.total_net_loss, r.total_return_qty, r.warehouse_cnt, r.avg_net_loss, r.loss_rank
ORDER BY r.loss_rank
