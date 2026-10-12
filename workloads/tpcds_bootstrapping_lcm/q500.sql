SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    p.p_promo_id,
    p.p_promo_name,
    d_ret.d_year,
    d_ret.d_month_seq,
    cd_ret.cd_gender,
    cd_ret.cd_education_status,
    COUNT(DISTINCT wr.wr_order_number) AS num_return_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(p.p_cost) AS total_promo_cost,
    COUNT(DISTINCT cd_ref.cd_demo_sk) AS num_refunded_demo,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_return_tax) AS total_tax
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN customer_demographics cd_ret
    ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN customer_demographics cd_ref
    ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
CROSS JOIN promotion p
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_ret.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date
  AND d_ret.d_year = 2020
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    p.p_promo_id,
    p.p_promo_name,
    d_ret.d_year,
    d_ret.d_month_seq,
    cd_ret.cd_gender,
    cd_ret.cd_education_status
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
