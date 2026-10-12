SELECT
    cp.cp_department,
    cp.cp_type,
    cp.cp_catalog_page_number,
    d_start.d_year AS start_year,
    d_start.d_month_seq AS start_month_seq,
    d_end.d_year AS end_year,
    d_end.d_month_seq AS end_month_seq,
    s.s_state,
    s.s_city,
    s.s_company_name,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_quantity) AS total_return_quantity,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_fee) AS avg_return_fee,
    SUM(wr.wr_return_tax) AS total_return_tax
FROM catalog_page cp
JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end   ON cp.cp_end_date_sk   = d_end.d_date_sk
JOIN store s          ON s.s_closed_date_sk  = d_end.d_date_sk
JOIN web_returns wr  ON wr.wr_returned_date_sk = d_end.d_date_sk
WHERE cp.cp_type = 'Promotion'
  AND s.s_state = 'TX'
  AND d_end.d_year = 2022
GROUP BY
    cp.cp_department,
    cp.cp_type,
    cp.cp_catalog_page_number,
    d_start.d_year,
    d_start.d_month_seq,
    d_end.d_year,
    d_end.d_month_seq,
    s.s_state,
    s.s_city,
    s.s_company_name
ORDER BY total_return_amount DESC
LIMIT 50
