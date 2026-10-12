SELECT
    cp.cp_department,
    cp.cp_catalog_page_id,
    cp.cp_description,
    d_start.d_year AS catalog_start_year,
    d_start.d_month_seq AS catalog_start_month_seq,
    d_start.d_date AS catalog_start_date,
    d_end.d_year AS catalog_end_year,
    d_end.d_month_seq AS catalog_end_month_seq,
    d_end.d_date AS catalog_end_date,
    d_promo_end.d_date AS promo_end_date,
    p.p_promo_id,
    p.p_cost,
    p.p_channel_tv,
    p.p_discount_active,
    s.s_store_name,
    s.s_city,
    s.s_number_employees,
    s.s_gmt_offset,
    ws.web_name,
    ws.web_city,
    d_web_close.d_date AS web_close_date,
    DATE_DIFF('day', d_start.d_date, d_end.d_date) AS catalog_page_duration_days,
    DATE_DIFF('day', d_start.d_date, d_web_close.d_date) AS days_until_web_close,
    CASE
        WHEN p.p_discount_active = 'Y' THEN p.p_cost * 0.85
        ELSE p.p_cost
    END AS effective_promo_cost,
    SUM(p.p_cost) OVER (PARTITION BY cp.cp_department) AS dept_total_promo_cost,
    ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY p.p_cost DESC) AS promo_rank_by_dept
FROM catalog_page cp
JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_end.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_start.d_date_sk
JOIN date_dim d_web_close ON ws.web_close_date_sk = d_web_close.d_date_sk
WHERE d_start.d_year = d_end.d_year
  AND p.p_discount_active IS NOT NULL
ORDER BY cp.cp_department, p.p_cost DESC
LIMIT 100
