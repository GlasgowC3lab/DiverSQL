SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_number_employees,
    cp.cp_department,
    cp.cp_catalog_page_number,
    cp.cp_type,
    cp.cp_description,
    ws.web_name,
    ws.web_city,
    d_sr.d_year,
    d_sr.d_month_seq,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_tickets,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_quantity) AS avg_return_quantity,
    SUM(sr.sr_fee) AS total_fee,
    MIN(d_sr.d_date) AS earliest_return_date,
    MAX(d_sr.d_date) AS latest_return_date,
    MAX(d_store_closed.d_date) AS store_close_date,
    MAX(d_cp_end.d_date) AS catalog_end_date,
    MAX(d_ws_close.d_date) AS website_close_date
FROM store_returns sr
INNER JOIN date_dim d_sr
    ON sr.sr_returned_date_sk = d_sr.d_date_sk
INNER JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
INNER JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
INNER JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_sr.d_date_sk
INNER JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
INNER JOIN web_site ws
    ON ws.web_open_date_sk = d_sr.d_date_sk
INNER JOIN date_dim d_ws_close
    ON ws.web_close_date_sk = d_ws_close.d_date_sk
WHERE d_sr.d_date BETWEEN d_store_closed.d_date AND d_cp_end.d_date
  AND d_sr.d_date <= d_ws_close.d_date
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_number_employees,
    cp.cp_department,
    cp.cp_catalog_page_number,
    cp.cp_type,
    cp.cp_description,
    ws.web_name,
    ws.web_city,
    d_sr.d_year,
    d_sr.d_month_seq
ORDER BY total_net_loss DESC
LIMIT 10
