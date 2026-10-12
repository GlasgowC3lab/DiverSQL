SELECT
    cp.cp_department,
    cp.cp_type,
    cp.cp_catalog_page_number,
    s.s_store_id,
    s.s_state,
    d_start.d_date AS catalog_start_date,
    d_end.d_date AS catalog_end_date,
    d_ret.d_date AS store_return_date,
    d_web.d_date AS web_return_date,
    d_closed.d_date AS store_closed_date,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt,
    (SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) AS total_net_loss
FROM
    catalog_page cp
    JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
    JOIN date_dim d_ret ON cp.cp_start_date_sk = d_ret.d_date_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN date_dim d_web ON cp.cp_end_date_sk = d_web.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d_web.d_date_sk
GROUP BY
    cp.cp_department,
    cp.cp_type,
    cp.cp_catalog_page_number,
    s.s_store_id,
    s.s_state,
    d_start.d_date,
    d_end.d_date,
    d_ret.d_date,
    d_web.d_date,
    d_closed.d_date
ORDER BY
    total_net_loss DESC
LIMIT 100
