WITH cc_agg AS (
   SELECT cc_state,
          cc_country,
          cc_city,
          cc_sq_ft,
          COUNT(*) AS cc_cnt,
          SUM(cc_sq_ft) AS total_sq_ft,
          AVG(cc_tax_percentage) AS avg_tax_pct,
          COUNT(DISTINCT cc_zip) AS distinct_zip_cnt
   FROM call_center
   WHERE cc_tax_percentage > 0.00
   GROUP BY cc_state, cc_country, cc_city, cc_sq_ft
),
ca_agg AS (
   SELECT ca_state,
          ca_country,
          COUNT(*) AS ca_cnt,
          COUNT(DISTINCT ca_zip) AS ca_distinct_zip,
          AVG(ca_gmt_offset) AS avg_gmt_offset
   FROM customer_address
   WHERE ca_state IS NOT NULL
   GROUP BY ca_state, ca_country
),
hd_agg AS (
   SELECT hd_income_band_sk,
          AVG(hd_vehicle_count) AS avg_vehicle_cnt,
          AVG(hd_dep_count) AS avg_dep_cnt,
          COUNT(*) AS hd_cnt
   FROM household_demographics
   GROUP BY hd_income_band_sk
),
time_agg AS (
   SELECT t_shift,
          t_meal_time,
          COUNT(*) AS time_cnt,
          AVG(t_hour) AS avg_hour
   FROM time_dim
   GROUP BY t_shift, t_meal_time
)
SELECT
   cc.cc_state,
   cc.cc_country,
   cc.cc_cnt,
   cc.total_sq_ft,
   cc.avg_tax_pct,
   ca.ca_cnt,
   ca.ca_distinct_zip,
   hd.avg_vehicle_cnt,
   time.t_shift,
   time.avg_hour,
   reason.r_reason_desc,
   RANK() OVER (PARTITION BY cc.cc_state ORDER BY cc.total_sq_ft DESC) AS state_sqft_rank
FROM cc_agg cc
JOIN ca_agg ca
   ON cc.cc_state = ca.ca_state AND cc.cc_country = ca.ca_country
LEFT JOIN hd_agg hd
   ON hd.hd_income_band_sk = CASE 
          WHEN cc.total_sq_ft > 500000000 THEN 1
          ELSE 2
        END
LEFT JOIN time_agg time
   ON time.t_shift = CASE 
          WHEN cc.cc_city = 'Greenwood' THEN 'Morning'
          WHEN cc.cc_city = 'Friendship' THEN 'Afternoon'
          ELSE 'Evening'
        END
CROSS JOIN (
   SELECT r_reason_desc
   FROM reason
   ORDER BY r_reason_sk
   LIMIT 1
) reason
WHERE cc.cc_cnt > 5
ORDER BY cc.total_sq_ft DESC
LIMIT 100
