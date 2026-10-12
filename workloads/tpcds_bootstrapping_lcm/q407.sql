SELECT
    d_start.d_year AS promo_start_year,
    d_end.d_year AS promo_end_year,
    s.s_state,
    s.s_city,
    s.s_division_name,
    s.s_number_employees,
    cc.cc_market_manager,
    cc.cc_state,
    cc.cc_city,
    ws.web_market_manager,
    ws.web_state,
    ws.web_city,
    SUM(p.p_cost) AS total_promo_cost,
    COUNT(DISTINCT p.p_promo_id) AS promo_count,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax,
    AVG(s.s_tax_percentage) AS avg_store_tax,
    AVG(ws.web_tax_percentage) AS avg_web_tax,
    CASE
        WHEN d_start.d_quarter_seq = d_end.d_quarter_seq THEN 'Same Quarter'
        ELSE 'Different Quarter'
    END AS promo_quarter_category,
    (d_end.d_year - d_start.d_year) AS promo_duration_years
FROM promotion p
JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_end.d_date_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d_end.d_date_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_web_close ON ws.web_close_date_sk = d_web_close.d_date_sk
WHERE d_start.d_year = d_end.d_year
GROUP BY
    d_start.d_year,
    d_end.d_year,
    s.s_state,
    s.s_city,
    s.s_division_name,
    s.s_number_employees,
    cc.cc_market_manager,
    cc.cc_state,
    cc.cc_city,
    ws.web_market_manager,
    ws.web_state,
    ws.web_city,
    CASE
        WHEN d_start.d_quarter_seq = d_end.d_quarter_seq THEN 'Same Quarter'
        ELSE 'Different Quarter'
    END,
    (d_end.d_year - d_start.d_year)
