WITH cd_agg AS (
    SELECT
        cd_gender,
        cd_education_status,
        cd_credit_rating,
        SUM(cd_purchase_estimate) AS total_purchase_est,
        AVG(cd_dep_count) AS avg_dep_count,
        COUNT(*) AS cust_cnt
    FROM customer_demographics
    WHERE cd_purchase_estimate >= 1500
      AND cd_education_status IN ('College', '4 yr Degree')
    GROUP BY cd_gender, cd_education_status, cd_credit_rating
),
hd_agg AS (
    SELECT
        hd_buy_potential,
        hd_income_band_sk,
        AVG(hd_vehicle_count) AS avg_vehicles,
        SUM(hd_dep_count) AS total_household_deps
    FROM household_demographics
    WHERE hd_income_band_sk BETWEEN 2 AND 5
    GROUP BY hd_buy_potential, hd_income_band_sk
),
wh_agg AS (
    SELECT
        w_state,
        COUNT(DISTINCT w_warehouse_id) AS wh_cnt,
        SUM(w_warehouse_sq_ft) AS total_sq_ft
    FROM warehouse
    WHERE w_gmt_offset BETWEEN -5 AND 5
    GROUP BY w_state
)
SELECT
    c.cd_gender,
    c.cd_education_status,
    c.cd_credit_rating,
    c.total_purchase_est,
    c.cust_cnt,
    h.avg_vehicles,
    w.wh_cnt,
    RANK() OVER (ORDER BY c.total_purchase_est DESC) AS purchase_rank
FROM cd_agg c
JOIN hd_agg h
  ON c.cd_credit_rating = h.hd_buy_potential
JOIN wh_agg w
  ON (c.cd_gender = 'M' AND w.w_state = 'TX')
     OR (c.cd_gender = 'F' AND w.w_state = 'CA')
WHERE h.hd_income_band_sk BETWEEN 3 AND 5
ORDER BY c.total_purchase_est DESC
LIMIT 20
