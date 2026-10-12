SELECT
  d.d_fy_year,
  COUNT(p.p_promo_id) AS promo_count,
  SUM(p.p_cost) AS total_cost
FROM promotion p
JOIN date_dim d
  ON p.p_start_date_sk = d.d_date_sk
WHERE d.d_fy_year = 1906
  AND p.p_channel_tv = 'N'
GROUP BY d.d_fy_year
ORDER BY d.d_fy_year
