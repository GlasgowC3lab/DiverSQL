SELECT
    cp.cp_type,
    cp.cp_catalog_number,
    s.s_state,
    d_return.d_year,
    d_return.d_moy AS month_of_year,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_orders,
    SUM(cr.cr_return_amount) AS total_catalog_return_amt,
    SUM(wr.wr_return_amt_inc_tax) AS total_web_return_amt,
    (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_catalog_ret_qty,
    AVG(wr.wr_return_quantity) AS avg_web_ret_qty,
    CASE
        WHEN SUM(cr.cr_return_amount) = 0 THEN NULL
        ELSE ROUND(SUM(wr.wr_return_amt_inc_tax) / SUM(cr.cr_return_amount), 2)
    END AS web_to_catalog_return_ratio,
    CASE
        WHEN (SUM(cr.cr_return_amount) + SUM(wr.wr_return_amt_inc_tax)) > 5000 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS return_level
FROM catalog_page cp
JOIN catalog_returns cr
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cp_end.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_return.d_date_sk
WHERE d_return.d_year >= 2020
  AND s.s_state IS NOT NULL
GROUP BY
    cp.cp_type,
    cp.cp_catalog_number,
    s.s_state,
    d_return.d_year,
    d_return.d_moy
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
