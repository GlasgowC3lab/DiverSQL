SELECT
    p.p_promo_id,
    s.s_store_id,
    d_ret.d_year,
    FLOOR(d_ret.d_year / 5) * 5 AS year_group,
    cd_r.cd_gender AS returning_gender,
    CASE
        WHEN cd_f.cd_credit_rating = 'A' THEN 'High'
        WHEN cd_f.cd_credit_rating = 'B' THEN 'Medium'
        ELSE 'Low'
    END AS refunded_credit_category,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_return_tax) AS total_return_tax,
    AVG(cd_r.cd_purchase_estimate) AS avg_returning_purchase_estimate,
    AVG(p.p_cost) AS avg_promo_cost,
    SUM(wr.wr_return_amt) / NULLIF(AVG(p.p_cost), 0) AS return_to_avg_promo_cost_ratio
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN customer_demographics cd_r
    ON wr.wr_returning_cdemo_sk = cd_r.cd_demo_sk
JOIN customer_demographics cd_f
    ON wr.wr_refunded_cdemo_sk = cd_f.cd_demo_sk
JOIN promotion p
    ON d_ret.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
GROUP BY
    p.p_promo_id,
    s.s_store_id,
    d_ret.d_year,
    FLOOR(d_ret.d_year / 5) * 5,
    cd_r.cd_gender,
    CASE
        WHEN cd_f.cd_credit_rating = 'A' THEN 'High'
        WHEN cd_f.cd_credit_rating = 'B' THEN 'Medium'
        ELSE 'Low'
    END
ORDER BY total_return_amount DESC
LIMIT 100
