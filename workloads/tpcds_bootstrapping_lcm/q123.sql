SELECT
    d.d_year,
    d.d_month_seq AS month_seq,
    CASE WHEN (d.d_month_seq % 2) = 0 THEN 'Even' ELSE 'Odd' END AS month_parity,
    s.s_state,
    p_start.p_channel_tv,
    p_end.p_channel_radio,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(cr.cr_return_tax) + SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(cr.cr_fee) + SUM(wr.wr_fee) AS total_fees,
    SUM(p_start.p_cost) AS total_start_promo_cost,
    SUM(p_end.p_cost) AS total_end_promo_cost,
    CASE 
        WHEN COALESCE(SUM(cr.cr_return_amount), 0) + COALESCE(SUM(wr.wr_return_amt), 0) = 0 THEN NULL
        ELSE (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) / (COALESCE(SUM(cr.cr_return_amount), 0) + COALESCE(SUM(wr.wr_return_amt), 0))
    END AS loss_to_return_ratio,
    COUNT(DISTINCT CASE WHEN p_start.p_discount_active = 'Y' THEN p_start.p_promo_id END) AS active_start_promo_cnt,
    COUNT(DISTINCT CASE WHEN p_end.p_discount_active = 'Y' THEN p_end.p_promo_id END) AS active_end_promo_cnt
FROM date_dim d
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN promotion p_start
    ON p_start.p_start_date_sk = d.d_date_sk
JOIN promotion p_end
    ON p_end.p_end_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_state,
    p_start.p_channel_tv,
    p_end.p_channel_radio,
    CASE WHEN (d.d_month_seq % 2) = 0 THEN 'Even' ELSE 'Odd' END
HAVING (SUM(cr.cr_return_quantity) + SUM(wr.wr_return_quantity)) > 0
ORDER BY
    d.d_year,
    d.d_month_seq
