SELECT
    d.d_year,
    d.d_month_seq,
    d.d_current_month,
    s.s_store_id,
    s.s_city,
    s.s_floor_space,
    p.p_promo_id,
    p.p_promo_name,
    p.p_discount_active,
    hd_refunded.hd_buy_potential AS refunded_buy_potential,
    hd_returning.hd_vehicle_count AS returning_vehicle_count,
    COUNT(wr.wr_order_number) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    SUM(wr.wr_return_tax) AS total_return_tax
FROM date_dim d
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd_refunded
    ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
    ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN promotion p
    ON d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
GROUP BY
    d.d_year,
    d.d_month_seq,
    d.d_current_month,
    s.s_store_id,
    s.s_city,
    s.s_floor_space,
    p.p_promo_id,
    p.p_promo_name,
    p.p_discount_active,
    hd_refunded.hd_buy_potential,
    hd_returning.hd_vehicle_count
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
