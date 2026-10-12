SELECT
    d_ret.d_year,
    d_ret.d_quarter_name,
    d_start.d_month_seq AS promo_start_month_seq,
    d_end.d_month_seq   AS promo_end_month_seq,
    s.s_division_name,
    p.p_promo_name,
    r.r_reason_desc,
    COUNT(DISTINCT wr.wr_order_number)                AS num_orders,
    SUM(wr.wr_return_amt)                             AS total_return_amount,
    SUM(wr.wr_net_loss)                               AS total_net_loss,
    AVG(p.p_cost)                                     AS avg_promo_cost,
    SUM(wr.wr_return_quantity)                        AS total_return_qty,
    CASE
        WHEN SUM(wr.wr_return_quantity) = 0 THEN NULL
        ELSE SUM(wr.wr_net_loss) / SUM(wr.wr_return_quantity)
    END                                              AS net_loss_per_item
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE p.p_discount_active = 'Y'
  AND r.r_reason_desc LIKE '%damage%'
GROUP BY
    d_ret.d_year,
    d_ret.d_quarter_name,
    d_start.d_month_seq,
    d_end.d_month_seq,
    s.s_division_name,
    p.p_promo_name,
    r.r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 100
