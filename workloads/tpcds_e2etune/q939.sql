SELECT
    cp.cp_type,
    cp.cp_department,
    COUNT(DISTINCT p.p_promo_id) AS promo_cnt,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(p.p_cost) AS avg_promo_cost,
    COUNT(DISTINCT r.r_reason_id) AS reason_cnt
FROM catalog_page AS cp
JOIN promotion AS p
    ON p.p_start_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
JOIN reason AS r
    ON p.p_promo_id = r.r_reason_id
WHERE cp.cp_type = 'monthly'
  AND p.p_discount_active = 'Y'
GROUP BY cp.cp_type, cp.cp_department
HAVING SUM(p.p_cost) > 10000
ORDER BY total_promo_cost DESC
LIMIT 20
