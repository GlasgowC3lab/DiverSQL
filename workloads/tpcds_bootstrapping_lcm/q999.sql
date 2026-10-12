SELECT
    cp.cp_department,
    d1.d_year,
    d1.d_month_seq,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS catalog_page_cnt,
    COUNT(DISTINCT s.s_store_id) AS closed_store_cnt,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(wp.wp_link_count) AS avg_wp_links,
    COUNT(DISTINCT wp.wp_web_page_id) AS web_page_cnt,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) AS active_discount_cost,
    SUM(p.p_cost) / NULLIF(COUNT(DISTINCT cp.cp_catalog_page_id), 0) AS promo_cost_per_page
FROM catalog_page cp
JOIN date_dim d1
    ON cp.cp_end_date_sk = d1.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d1.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d1.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d1.d_date_sk
WHERE cp.cp_type = 'Catalog'
  AND s.s_state = 'CA'
  AND wp.wp_type = 'Landing'
  AND d1.d_year BETWEEN 2015 AND 2020
  AND d1.d_dow BETWEEN 1 AND 5
GROUP BY cp.cp_department, d1.d_year, d1.d_month_seq
HAVING SUM(p.p_cost) > 1000
ORDER BY promo_cost_per_page DESC
LIMIT 100
