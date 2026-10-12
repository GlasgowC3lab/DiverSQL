WITH dept_quarter_agg AS (
  SELECT
    cp.cp_department,
    d_return.d_quarter_seq AS quarter_seq,
    s.s_store_name,
    wp.wp_url,
    d_end.d_month_seq AS cp_end_month,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    COUNT(*) AS return_cnt
  FROM catalog_returns cr
  JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
  JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
  JOIN web_page wp
    ON wp.wp_creation_date_sk = d_return.d_date_sk
  JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
  GROUP BY
    cp.cp_department,
    d_return.d_quarter_seq,
    s.s_store_name,
    wp.wp_url,
    d_end.d_month_seq
)
SELECT
  cp_department,
  quarter_seq,
  cp_end_month,
  s_store_name,
  wp_url,
  total_net_loss,
  avg_return_amount,
  avg_return_qty,
  return_cnt,
  RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM dept_quarter_agg
ORDER BY net_loss_rank
LIMIT 100
