SELECT
    d.d_year,
    CASE
        WHEN d.d_month_seq <= 6 THEN 'H1'
        ELSE 'H2'
    END AS half_year,
    sm.sm_type,
    s.s_state,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_quantity) AS catalog_return_qty,
    SUM(wr.wr_return_quantity) AS web_return_qty,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    SUM(wr.wr_return_amt) AS web_return_amount,
    SUM(cr.cr_net_loss + wr.wr_net_loss) AS total_net_loss,
    AVG(cr.cr_fee + wr.wr_fee) AS avg_combined_fee,
    SUM(cr.cr_return_ship_cost + wr.wr_return_ship_cost) AS total_combined_ship_cost,
    MIN(d.d_date) AS first_return_date,
    MAX(d.d_date) AS last_return_date
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY
    d.d_year,
    CASE
        WHEN d.d_month_seq <= 6 THEN 'H1'
        ELSE 'H2'
    END,
    sm.sm_type,
    s.s_state
HAVING COUNT(*) > 20
ORDER BY d.d_year DESC, half_year, sm.sm_type
