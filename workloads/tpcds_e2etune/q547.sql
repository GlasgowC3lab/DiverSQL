WITH cc_raw AS (
  SELECT cc_country,
         cc_state,
         cc_city,
         SUM(cc_employees) AS total_employees,
         AVG(cc_sq_ft) AS avg_sq_ft,
         COUNT(*) AS num_centers
  FROM call_center
  WHERE cc_rec_end_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
    AND cc_class IN ('large', 'medium')
  GROUP BY cc_country, cc_state, cc_city
),
cc_agg AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY cc_state ORDER BY total_employees DESC) AS rnk_state
  FROM cc_raw
),
promo_agg AS (
  SELECT p_channel_tv,
         p_channel_email,
         COUNT(*) AS promo_count,
         AVG(p_cost) AS avg_cost,
         SUM(p_response_target) AS total_response_target
  FROM promotion
  WHERE p_start_date_sk BETWEEN 2451545 AND 2451910
  GROUP BY p_channel_tv, p_channel_email
),
ship_agg AS (
  SELECT sm_type,
         sm_carrier,
         COUNT(*) AS ship_mode_count,
         COUNT(DISTINCT sm_contract) AS distinct_contracts
  FROM ship_mode
  GROUP BY sm_type, sm_carrier
)
SELECT cc.cc_country,
       cc.cc_state,
       cc.cc_city,
       cc.total_employees,
       cc.avg_sq_ft,
       cc.num_centers,
       cc.rnk_state,
       p.promo_count,
       p.avg_cost,
       p.total_response_target,
       s.ship_mode_count,
       s.distinct_contracts
FROM cc_agg cc
JOIN promo_agg p ON 1 = 1
JOIN ship_agg s ON 1 = 1
WHERE cc.rnk_state <= 5
ORDER BY cc.total_employees DESC, p.avg_cost ASC
LIMIT 100
