WITH cd_agg AS (
    SELECT
        cd_gender,
        cd_marital_status,
        AVG(cd_purchase_estimate) AS avg_purchase_est,
        COUNT(*) AS cust_cnt
    FROM customer_demographics
    WHERE cd_credit_rating = 'Good'
      AND cd_education_status = 'College'
    GROUP BY cd_gender, cd_marital_status
),
wh_date_join AS (
    SELECT
        w.w_state,
        w.w_gmt_offset,
        w.w_warehouse_sq_ft,
        w.w_warehouse_sk,
        d.d_year,
        d.d_holiday
    FROM warehouse w
    JOIN date_dim d
      ON (w.w_warehouse_sk % 7) = d.d_dow
    WHERE w.w_country = 'United States'
      AND d.d_year BETWEEN 2015 AND 2020
)
SELECT
    whd.w_state,
    COUNT(DISTINCT whd.w_warehouse_sk) AS warehouse_cnt,
    AVG(whd.w_gmt_offset) AS avg_gmt_offset,
    SUM(whd.w_warehouse_sq_ft) AS total_sq_ft,
    SUM(CASE WHEN whd.d_holiday = 'Y' THEN 1 ELSE 0 END) AS holiday_count,
    cd.avg_purchase_est,
    cd.cust_cnt,
    RANK() OVER (ORDER BY AVG(whd.w_gmt_offset) DESC, cd.avg_purchase_est DESC) AS state_rank
FROM wh_date_join whd
LEFT JOIN cd_agg cd
    ON cd.cd_gender = SUBSTRING(whd.w_state FROM 1 FOR 1)
   AND cd.cd_marital_status = 'M'
GROUP BY whd.w_state, cd.avg_purchase_est, cd.cust_cnt
HAVING COUNT(DISTINCT whd.w_warehouse_sk) >= 2
ORDER BY state_rank
LIMIT 20
