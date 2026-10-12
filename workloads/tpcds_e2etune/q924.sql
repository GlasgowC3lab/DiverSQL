WITH ib_agg AS (
    SELECT ib_income_band_sk,
           COUNT(*) AS ib_cnt,
           SUM(ib_upper_bound - ib_lower_bound) AS ib_range_sum,
           AVG(ib_upper_bound) AS ib_avg_ub
    FROM income_band
    WHERE ib_lower_bound >= 10001
    GROUP BY ib_income_band_sk
),
reason_agg AS (
    SELECT r_reason_sk,
           COUNT(*) AS r_cnt,
           MAX(LENGTH(r_reason_desc)) AS r_desc_len_max
    FROM reason
    WHERE r_reason_id LIKE 'AAAA%'
    GROUP BY r_reason_sk
)
SELECT w.w_state,
       ib_agg.ib_income_band_sk,
       reason_agg.r_reason_sk,
       COUNT(*) AS warehouse_cnt,
       SUM(w.w_warehouse_sq_ft) AS total_sqft,
       AVG(w.w_gmt_offset) AS avg_gmt_offset,
       ib_agg.ib_cnt,
       reason_agg.r_cnt,
       RANK() OVER (ORDER BY SUM(w.w_warehouse_sq_ft) DESC) AS state_sqft_rank
FROM warehouse w
CROSS JOIN ib_agg
CROSS JOIN reason_agg
WHERE w.w_country = 'United States'
  AND w.w_gmt_offset BETWEEN -5.00 AND 5.00
GROUP BY w.w_state, ib_agg.ib_income_band_sk, reason_agg.r_reason_sk, ib_agg.ib_cnt, reason_agg.r_cnt
HAVING COUNT(*) > 5
ORDER BY total_sqft DESC
LIMIT 100
