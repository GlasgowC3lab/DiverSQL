SELECT
    d_return.d_year,
    d_return.d_quarter_name,
    cc.cc_name,
    cc.cc_city,
    s.s_store_name,
    s.s_city,
    ws.web_name,
    ws.web_city,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_store_credit) AS total_store_credit,
    AVG(sr.sr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
    MIN(d_cc_open.d_date) AS call_center_open_date,
    MAX(d_return.d_date) AS call_center_close_date,
    MIN(d_ws_open.d_date) AS web_site_open_date,
    MAX(d_ws_close.d_date) AS web_site_close_date,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax_pct,
    AVG(ws.web_tax_percentage) AS avg_ws_tax_pct,
    SUM(sr.sr_return_amt) / NULLIF(SUM(sr.sr_store_credit), 0) AS return_to_credit_ratio,
    MAX(d_store_closed.d_month_seq) AS store_closed_month_seq
FROM store_returns sr
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_return.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_return.d_date_sk
JOIN date_dim d_ws_open
    ON ws.web_open_date_sk = d_ws_open.d_date_sk
JOIN date_dim d_ws_close
    ON ws.web_close_date_sk = d_ws_close.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_return.d_year BETWEEN 2015 AND 2020
  AND s.s_state = cc.cc_state
  AND ws.web_state = s.s_state
GROUP BY
    d_return.d_year,
    d_return.d_quarter_name,
    cc.cc_name,
    cc.cc_city,
    s.s_store_name,
    s.s_city,
    ws.web_name,
    ws.web_city
ORDER BY total_return_amount DESC
LIMIT 100
