SELECT
    d.d_year,
    d.d_quarter_seq,
    CASE WHEN d.d_month_seq % 2 = 0 THEN 'Even' ELSE 'Odd' END AS month_parity,
    i.i_category,
    i.i_brand,
    r.r_reason_desc,
    s.s_state,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_quantity) AS total_quantity,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_quantity,
    SUM(wr.wr_fee) AS total_fees,
    SUM(wr.wr_return_tax) AS total_tax,
    SUM(CASE WHEN wr.wr_net_loss > 0 THEN wr.wr_net_loss ELSE 0 END) /
        NULLIF(SUM(wr.wr_return_amt), 0) AS loss_to_return_ratio,
    MAX(d.d_date) AS latest_return_date
FROM web_returns wr
JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND i.i_category IS NOT NULL
GROUP BY
    d.d_year,
    d.d_quarter_seq,
    CASE WHEN d.d_month_seq % 2 = 0 THEN 'Even' ELSE 'Odd' END,
    i.i_category,
    i.i_brand,
    r.r_reason_desc,
    s.s_state
HAVING COUNT(*) > 10
ORDER BY total_net_loss DESC
LIMIT 100
