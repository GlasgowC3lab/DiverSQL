SELECT
    cp.cp_catalog_page_id,
    cp.cp_type,
    d_start.d_year AS start_year,
    d_start.d_month_seq AS start_month,
    d_end.d_year AS end_year,
    d_end.d_month_seq AS end_month,
    s.s_store_name,
    s.s_city,
    r.r_reason_desc,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_tax) AS avg_return_tax,
    MIN(wr.wr_returned_date_sk) AS min_returned_date_sk,
    MAX(wr.wr_returned_date_sk) AS max_returned_date_sk
FROM catalog_page cp
JOIN date_dim d_start
  ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
  ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d_end.d_date_sk
JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
JOIN store s
  ON s.s_closed_date_sk = d_end.d_date_sk
WHERE cp.cp_type = 'Promotion'
  AND r.r_reason_desc LIKE '%defect%'
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_type,
    d_start.d_year,
    d_start.d_month_seq,
    d_end.d_year,
    d_end.d_month_seq,
    s.s_store_name,
    s.s_city,
    r.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
