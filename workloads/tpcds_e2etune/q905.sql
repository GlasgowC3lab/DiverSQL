SELECT
    ib.ib_income_band_sk AS income_band_id,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    p.p_purpose,
    COUNT(DISTINCT p.p_promo_id) AS promo_cnt,
    SUM(p.p_cost) AS total_cost,
    AVG(p.p_cost) AS avg_cost,
    COUNT(DISTINCT r.r_reason_id) AS distinct_reason_cnt,
    RANK() OVER (ORDER BY SUM(p.p_cost) DESC) AS cost_rank
FROM promotion p
JOIN income_band ib
  ON p.p_response_target BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
LEFT JOIN reason r
  ON p.p_promo_id = r.r_reason_id
WHERE p.p_discount_active = 'Y'
  AND p.p_channel_tv = 'Y'
  AND p.p_channel_press = 'N'
  AND p.p_channel_demo = 'N'
  AND p.p_purpose = 'Unknown'
  AND p.p_start_date_sk >= 20200101
  AND p.p_end_date_sk <= 20221231
GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, p.p_purpose
HAVING COUNT(DISTINCT p.p_promo_id) >= 5
ORDER BY total_cost DESC
LIMIT 50
