SELECT
    cc.cc_name AS call_center_name,
    cc.cc_city AS call_center_city,
    s.s_store_name AS store_name,
    s.s_city AS store_city,
    ws.web_name AS website_name,
    ws.web_city AS website_city,
    d_ret.d_year AS return_year,
    d_ret.d_current_month AS return_month,
    d_cc_open.d_year AS call_center_open_year,
    d_ws_close.d_year AS website_close_year,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    COUNT(*) AS return_count,
    AVG(wr.wr_fee) AS avg_fee,
    MAX(wr.wr_net_loss) AS max_net_loss,
    cc.cc_tax_percentage AS call_center_tax_percentage,
    ws.web_tax_percentage AS website_tax_percentage,
    (cc.cc_tax_percentage - ws.web_tax_percentage) AS tax_percentage_diff
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_ret.d_date_sk
JOIN date_dim d_ws_close
    ON ws.web_close_date_sk = d_ws_close.d_date_sk
GROUP BY
    cc.cc_name,
    cc.cc_city,
    s.s_store_name,
    s.s_city,
    ws.web_name,
    ws.web_city,
    d_ret.d_year,
    d_ret.d_current_month,
    d_cc_open.d_year,
    d_ws_close.d_year,
    cc.cc_tax_percentage,
    ws.web_tax_percentage
ORDER BY
    total_return_amount DESC,
    return_year,
    call_center_name
