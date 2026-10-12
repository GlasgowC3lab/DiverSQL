WITH hd_income AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(*) AS household_cnt,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt,
        SUM(hd.hd_dep_count) AS total_dependents
    FROM household_demographics hd
    JOIN income_band ib 
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_vehicle_count > 0
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
cc_stats AS (
    SELECT 
        cc.cc_division,
        cc.cc_state,
        COUNT(DISTINCT cc.cc_call_center_id) AS num_call_centers,
        AVG(cc.cc_sq_ft) AS avg_sq_ft,
        SUM(cc.cc_tax_percentage) AS total_tax_percentage
    FROM call_center cc
    WHERE cc.cc_rec_end_date > DATE '2000-01-01'
    GROUP BY cc.cc_division, cc.cc_state
),
promo_stats AS (
    SELECT 
        p.p_channel_email,
        COUNT(*) AS promo_count,
        AVG(p.p_cost) AS avg_cost,
        SUM(p.p_response_target) AS total_response_target
    FROM promotion p
    WHERE p.p_start_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY p.p_channel_email
),
ship_stats AS (
    SELECT 
        sm.sm_type,
        COUNT(*) AS ship_mode_cnt,
        AVG(sm.sm_ship_mode_sk) AS avg_ship_mode_sk
    FROM ship_mode sm
    GROUP BY sm.sm_type
)
SELECT 
    hd.ib_income_band_sk,
    hd.ib_lower_bound,
    hd.ib_upper_bound,
    hd.household_cnt,
    hd.avg_vehicle_cnt,
    cc.cc_division,
    cc.cc_state,
    cc.num_call_centers,
    cc.avg_sq_ft,
    p.p_channel_email,
    p.promo_count,
    p.avg_cost,
    s.sm_type,
    s.ship_mode_cnt,
    s.avg_ship_mode_sk
FROM hd_income hd
CROSS JOIN cc_stats cc
CROSS JOIN promo_stats p
CROSS JOIN ship_stats s
WHERE hd.household_cnt > 10
  AND cc.num_call_centers >= 1
  AND p.promo_count > 0
  AND s.ship_mode_cnt >= 1
ORDER BY hd.household_cnt DESC, cc.cc_division, p.promo_count DESC
LIMIT 100
