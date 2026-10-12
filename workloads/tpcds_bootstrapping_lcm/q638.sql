SELECT
    d_ret.d_date AS return_date,
    d_closed.d_date AS store_closed_date,
    d_end.d_date AS promo_end_date,
    s.s_state,
    s.s_city,
    p.p_promo_name,
    p.p_discount_active,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
    SUM(sr.sr_net_loss) AS store_total_net_loss,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt,
    SUM(wr.wr_net_loss) AS web_total_net_loss,
    SUM(p.p_cost) AS total_promo_cost,
    CASE
        WHEN SUM(p.p_cost) > 0 THEN (SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) / SUM(p.p_cost)
        ELSE NULL
    END AS loss_to_promo_cost_ratio
FROM date_dim d_ret
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_store_sk = sr.sr_store_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
WHERE d_ret.d_year = 2022
GROUP BY
    d_ret.d_date,
    d_closed.d_date,
    d_end.d_date,
    s.s_state,
    s.s_city,
    p.p_promo_name,
    p.p_discount_active
ORDER BY d_ret.d_date ASC
LIMIT 100
