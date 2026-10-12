SELECT
    cc.cc_division,
    d_cc_closed.d_year AS cc_closed_year,
    d_cc_open.d_year AS cc_open_year,
    date_diff('day', d_cc_open.d_date, d_cc_closed.d_date) AS cc_operating_days,
    s.s_store_name,
    s.s_city,
    s.s_floor_space,
    d_store_closed.d_year AS store_closed_year,
    p.p_promo_name,
    p.p_cost,
    d_p_start.d_year AS promo_start_year,
    d_p_end.d_year AS promo_end_year,
    date_diff('day', d_p_start.d_date, d_p_end.d_date) AS promo_duration_days,
    w.web_name,
    w.web_city,
    d_ws_open.d_year AS web_open_year,
    d_ws_close.d_year AS web_close_year,
    date_diff('day', d_ws_open.d_date, d_ws_close.d_date) AS web_operating_days,
    (cc.cc_tax_percentage + s.s_tax_percentage + w.web_tax_percentage) / 3.0 AS avg_tax_percentage,
    CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost * 0.9 ELSE p.p_cost END AS discounted_cost,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_division ORDER BY d_cc_closed.d_date DESC) AS rn,
    (SELECT MAX(p2.p_cost)
       FROM promotion p2
       JOIN date_dim d2 ON p2.p_start_date_sk = d2.d_date_sk
      WHERE d2.d_year = d_cc_open.d_year) AS max_promo_cost_same_year
FROM call_center cc
JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_p_start ON p.p_start_date_sk = d_p_start.d_date_sk
JOIN date_dim d_p_end ON p.p_end_date_sk = d_p_end.d_date_sk
JOIN web_site w ON w.web_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_ws_open ON w.web_open_date_sk = d_ws_open.d_date_sk
JOIN date_dim d_ws_close ON w.web_close_date_sk = d_ws_close.d_date_sk
WHERE cc.cc_tax_percentage > 5
  AND p.p_discount_active = 'Y'
  AND w.web_tax_percentage < 10
ORDER BY cc.cc_division, d_cc_closed.d_year DESC
LIMIT 100
