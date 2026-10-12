SELECT
    d_start.d_year,
    d_start.d_month_seq,
    i.i_category,
    i.i_brand,
    s.s_state,
    COUNT(DISTINCT p.p_promo_id) AS promo_cnt,
    SUM(p.p_cost) AS total_promo_cost,
    SUM(p.p_cost) / NULLIF(COUNT(DISTINCT p.p_promo_id), 0) AS avg_cost_per_promo,
    SUM(CASE WHEN d_start.d_weekend = 'Y' THEN p.p_cost ELSE 0 END) AS weekend_promo_cost,
    SUM(CASE WHEN wp.wp_type = 'Landing' THEN p.p_cost ELSE 0 END) AS landing_promo_cost,
    AVG(i.i_current_price) AS avg_item_price,
    COUNT(DISTINCT wp.wp_web_page_id) AS web_page_cnt
FROM promotion p
JOIN item i
  ON p.p_item_sk = i.i_item_sk
JOIN date_dim d_start
  ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
  ON p.p_end_date_sk = d_end.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_end.d_date_sk
JOIN web_page wp
  ON wp.wp_creation_date_sk = d_start.d_date_sk
JOIN date_dim d_access
  ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE s.s_state = 'CA'
  AND i.i_category IS NOT NULL
  AND d_start.d_year = 2022
GROUP BY ROLLUP (d_start.d_year, d_start.d_month_seq, i.i_category, i.i_brand, s.s_state)
HAVING SUM(p.p_cost) > 1000
ORDER BY total_promo_cost DESC
LIMIT 100
