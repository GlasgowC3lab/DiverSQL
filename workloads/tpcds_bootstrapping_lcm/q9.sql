SELECT
    cc.cc_division_name,
    s.s_division_name,
    d_closed.d_year AS closed_year,
    d_open.d_year AS open_year,
    d_closed.d_quarter_name,
    COUNT(DISTINCT p.p_promo_id) AS promo_count,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax,
    AVG(s.s_tax_percentage) AS avg_s_tax,
    MIN(d_start.d_date) AS earliest_promo_start,
    MAX(d_end.d_date) AS latest_promo_end,
    COUNT(*) AS total_rows
FROM call_center cc
JOIN date_dim d_closed ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open   ON cc.cc_open_date_sk   = d_open.d_date_sk
JOIN promotion p       ON p.p_start_date_sk   = d_closed.d_date_sk
JOIN date_dim d_start  ON p.p_start_date_sk   = d_start.d_date_sk
JOIN date_dim d_end    ON p.p_end_date_sk     = d_end.d_date_sk
JOIN store s           ON s.s_closed_date_sk  = d_closed.d_date_sk
GROUP BY
    cc.cc_division_name,
    s.s_division_name,
    d_closed.d_year,
    d_open.d_year,
    d_closed.d_quarter_name
HAVING SUM(p.p_cost) > 5000
ORDER BY total_promo_cost DESC
LIMIT 100
