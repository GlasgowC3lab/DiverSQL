SELECT
    cd.cd_gender,
    cd.cd_education_status,
    d.d_year,
    s.s_store_name,
    s.s_city,
    s.s_state,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_count,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_count
FROM customer_demographics cd
JOIN store_returns sr
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
    AND s.s_closed_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    AND wr.wr_returned_date_sk = d.d_date_sk
GROUP BY
    cd.cd_gender,
    cd.cd_education_status,
    d.d_year,
    s.s_store_name,
    s.s_city,
    s.s_state
ORDER BY total_store_net_loss DESC
LIMIT 100
