SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_number,
    d_start.d_date AS start_date,
    d_end.d_date AS end_date,
    s.s_store_id,
    s.s_store_name,
    s.s_division_name,
    d_closure.d_date AS store_closed_date,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    AVG(sr.sr_return_quantity) AS avg_store_return_qty,
    AVG(wr.wr_return_quantity) AS avg_web_return_qty,
    SUM(sr.sr_return_amt_inc_tax) AS total_store_return_amt_inc_tax,
    SUM(wr.wr_return_amt_inc_tax) AS total_web_return_amt_inc_tax
FROM catalog_page cp
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_sr
    ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN date_dim d_closure
    ON s.s_closed_date_sk = d_closure.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_catalog_number,
    d_start.d_date,
    d_end.d_date,
    s.s_store_id,
    s.s_store_name,
    s.s_division_name,
    d_closure.d_date
ORDER BY total_store_net_loss DESC
LIMIT 100
