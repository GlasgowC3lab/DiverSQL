SELECT
    d_ret.d_current_year AS year,
    d_ret.d_quarter_name AS quarter,
    CASE WHEN d_ret.d_moy <= 6 THEN 'H1' ELSE 'H2' END AS half_year,
    s.s_state AS state,
    r.r_reason_desc AS reason,
    p.p_promo_name AS promo_name,
    COUNT(*) AS return_cnt,
    SUM(wr.wr_return_quantity) AS total_quantity,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_amt) AS avg_return_amt,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN wr.wr_return_amt ELSE 0 END) AS discount_active_return_amt,
    SUM(CASE WHEN p.p_cost > 10000 THEN wr.wr_return_amt ELSE 0 END) AS high_cost_promo_return_amt,
    ROUND(SUM(wr.wr_net_loss) / NULLIF(SUM(wr.wr_return_amt), 0), 4) AS loss_ratio,
    MIN(d_start.d_date) AS promo_start_date,
    MAX(d_end.d_date) AS promo_end_date
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
WHERE CAST(d_ret.d_current_year AS integer) >= 2015
  AND s.s_state IS NOT NULL
GROUP BY
    d_ret.d_current_year,
    d_ret.d_quarter_name,
    CASE WHEN d_ret.d_moy <= 6 THEN 'H1' ELSE 'H2' END,
    s.s_state,
    r.r_reason_desc,
    p.p_promo_name
HAVING COUNT(*) > 10
ORDER BY total_return_amt DESC
LIMIT 100
