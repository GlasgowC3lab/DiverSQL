SELECT
    d.d_current_year,
    d.d_current_quarter,
    i.i_category,
    i.i_brand,
    r.r_reason_desc,
    s.s_state,
    CASE WHEN s.s_tax_percentage > 5 THEN 'HighTax' ELSE 'LowTax' END AS tax_category,
    COUNT(*) AS return_count,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    MAX(wr.wr_return_amt_inc_tax) AS max_return_amount_inc_tax,
    SUM(wr.wr_net_loss) / NULLIF(COUNT(*), 0) AS avg_net_loss_per_return
FROM date_dim d
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year >= 2020
GROUP BY
    d.d_current_year,
    d.d_current_quarter,
    i.i_category,
    i.i_brand,
    r.r_reason_desc,
    s.s_state,
    CASE WHEN s.s_tax_percentage > 5 THEN 'HighTax' ELSE 'LowTax' END
HAVING SUM(wr.wr_return_amt) > 5000
ORDER BY total_return_amount DESC
LIMIT 100
