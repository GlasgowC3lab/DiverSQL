SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    hd_ret.hd_buy_potential          AS returning_buy_potential,
    hd_ref.hd_income_band_sk         AS refunded_income_band,
    s.s_store_name,
    s.s_floor_space,
    p_start.p_promo_name             AS start_promo_name,
    p_end.p_promo_name               AS end_promo_name,
    SUM(wr.wr_return_amt)            AS total_return_amount,
    SUM(wr.wr_net_loss)              AS total_net_loss,
    AVG(wr.wr_return_quantity)       AS avg_return_quantity,
    COUNT(*)                         AS return_count
FROM date_dim d
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd_ref
    ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics hd_ret
    ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN promotion p_start
    ON p_start.p_start_date_sk = d.d_date_sk
JOIN promotion p_end
    ON p_end.p_end_date_sk = d.d_date_sk
GROUP BY
    d.d_date,
    d.d_year,
    d.d_month_seq,
    hd_ret.hd_buy_potential,
    hd_ref.hd_income_band_sk,
    s.s_store_name,
    s.s_floor_space,
    p_start.p_promo_name,
    p_end.p_promo_name
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
