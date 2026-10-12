SELECT
    d.d_year,
    d.d_month_seq,
    d.d_quarter_name,
    s.s_state,
    s.s_city,
    p_start.p_promo_name AS promo_start_name,
    p_end.p_promo_name AS promo_end_name,
    CASE
        WHEN d.d_month_seq BETWEEN 1 AND 6 THEN 'H1'
        ELSE 'H2'
    END AS half_year,
    COUNT(DISTINCT wr.wr_order_number) AS order_cnt,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(p_start.p_cost) AS total_promo_start_cost,
    SUM(p_end.p_cost) AS total_promo_end_cost,
    SUM(wr.wr_return_quantity * p_start.p_cost) AS weighted_start_cost,
    SUM(wr.wr_return_quantity * p_end.p_cost) AS weighted_end_cost,
    ROUND(
        SUM(wr.wr_return_amt) / NULLIF(SUM(p_start.p_cost + p_end.p_cost), 0),
        2
    ) AS return_to_promo_cost_ratio
FROM date_dim d
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN promotion p_start
    ON p_start.p_start_date_sk = d.d_date_sk
JOIN promotion p_end
    ON p_end.p_end_date_sk = d.d_date_sk
WHERE d.d_year = 2022
  AND s.s_state = 'CA'
  AND p_start.p_discount_active = 'Y'
GROUP BY
    d.d_year,
    d.d_month_seq,
    d.d_quarter_name,
    s.s_state,
    s.s_city,
    p_start.p_promo_name,
    p_end.p_promo_name
HAVING SUM(wr.wr_return_amt) > 1000
