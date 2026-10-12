SELECT
    cc.cc_company_name,
    s.s_store_name,
    r.r_reason_desc,
    d_closed.d_year AS closed_year,
    d_closed.d_moy AS closed_month,
    d_open.d_year AS open_year,
    d_open.d_moy AS open_month,
    date_diff('day', d_open.d_date, d_closed.d_date) AS days_to_close,
    CASE WHEN d_closed.d_moy BETWEEN 1 AND 6 THEN 'H1' ELSE 'H2' END AS closed_half_year,
    COUNT(*) AS return_cnt,
    SUM(wr.wr_return_quantity) AS total_quantity,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_amt) AS avg_return_amt,
    SUM(wr.wr_return_amt) / NULLIF(SUM(wr.wr_return_quantity), 0) AS avg_amt_per_quantity,
    SUM(wr.wr_return_tax) AS total_tax,
    CASE WHEN SUM(wr.wr_return_amt) = 0 THEN NULL ELSE SUM(wr.wr_return_tax) / SUM(wr.wr_return_amt) END AS tax_rate
FROM call_center cc
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_closed.d_date_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
WHERE d_closed.d_year >= 2020
GROUP BY
    cc.cc_company_name,
    s.s_store_name,
    r.r_reason_desc,
    d_closed.d_year,
    d_closed.d_moy,
    d_open.d_year,
    d_open.d_moy,
    date_diff('day', d_open.d_date, d_closed.d_date),
    CASE WHEN d_closed.d_moy BETWEEN 1 AND 6 THEN 'H1' ELSE 'H2' END
ORDER BY total_net_loss DESC
LIMIT 100
