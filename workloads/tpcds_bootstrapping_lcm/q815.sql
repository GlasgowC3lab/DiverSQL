SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    p.p_promo_name,
    d_start.d_date AS promo_start_date,
    d_end.d_date AS promo_end_date,
    cd_ret.cd_gender AS returning_gender,
    cd_ret.cd_education_status AS returning_education,
    cd_ref.cd_gender AS refunded_gender,
    cd_ref.cd_education_status AS refunded_education,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_return_amt + wr.wr_return_tax) AS total_return_with_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(p.p_cost) AS total_promo_cost,
    CASE
        WHEN SUM(wr.wr_net_loss) > 1000 THEN 'High'
        ELSE 'Low'
    END AS net_loss_category,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(wr.wr_return_amt) DESC) AS store_return_rank
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN customer_demographics cd_ref
    ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
    ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    p.p_promo_name,
    d_start.d_date,
    d_end.d_date,
    cd_ret.cd_gender,
    cd_ret.cd_education_status,
    cd_ref.cd_gender,
    cd_ref.cd_education_status
ORDER BY total_return_amount DESC
LIMIT 100
