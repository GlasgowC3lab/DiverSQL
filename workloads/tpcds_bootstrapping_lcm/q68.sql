SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    r.r_reason_desc,
    s.s_store_id,
    s.s_state,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
    AVG(wr.wr_return_quantity) AS avg_web_return_qty,
    (SUM(cr.cr_fee) + SUM(wr.wr_fee)) AS total_fees,
    (SUM(cr.cr_reversed_charge) + SUM(wr.wr_reversed_charge)) AS total_reversed_charges,
    CASE
        WHEN (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) > 0 THEN 'Positive Loss'
        WHEN (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) < 0 THEN 'Negative Loss'
        ELSE 'Zero Loss'
    END AS net_loss_category
FROM date_dim d
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN reason r
    ON r.r_reason_sk = cr.cr_reason_sk
    AND r.r_reason_sk = wr.wr_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2020 AND 2022
  AND s.s_state IS NOT NULL
GROUP BY
    d.d_date,
    d.d_year,
    d.d_month_seq,
    r.r_reason_desc,
    s.s_store_id,
    s.s_state
HAVING (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) <> 0
ORDER BY d.d_date DESC, total_catalog_net_loss DESC
LIMIT 100
