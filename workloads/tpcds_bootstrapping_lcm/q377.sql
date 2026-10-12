SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_sc.d_year AS store_closed_year,
    d_sr.d_year AS store_return_year,
    d_wr.d_year AS web_return_year,
    cd.cd_credit_rating,
    cd.cd_gender,
    cd_ret.cd_education_status AS returning_education_status,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_store_returns,
    SUM(sr.sr_net_loss) AS store_total_net_loss,
    COUNT(DISTINCT wr.wr_order_number) AS num_web_returns,
    SUM(wr.wr_net_loss) AS web_total_net_loss,
    SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS overall_net_loss
FROM store s
JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_sr
    ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN web_returns wr
    ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN customer_demographics cd_ret
    ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN date_dim d_sc
    ON s.s_closed_date_sk = d_sc.d_date_sk
WHERE d_sr.d_year = 2022
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_sc.d_year,
    d_sr.d_year,
    d_wr.d_year,
    cd.cd_credit_rating,
    cd.cd_gender,
    cd_ret.cd_education_status
ORDER BY overall_net_loss DESC
LIMIT 100
