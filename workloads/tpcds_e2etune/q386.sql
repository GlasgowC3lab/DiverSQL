WITH agg AS (
    SELECT
        ws.web_site_id,
        ws.web_name,
        cd.cd_education_status,
        COUNT(DISTINCT cd.cd_demo_sk) AS num_customers,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(hd.hd_vehicle_count) AS total_vehicles,
        AVG(hd.hd_vehicle_count) AS avg_vehicles,
        SUM(cd.cd_dep_count) AS total_dependents,
        AVG(cd.cd_dep_employed_count) AS avg_employed_dependents
    FROM customer_demographics cd
    JOIN household_demographics hd
        ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN web_site ws
        ON hd.hd_income_band_sk = ws.web_mkt_id
    WHERE cd.cd_credit_rating = 'Good'
      AND cd.cd_gender = 'F'
      AND ws.web_rec_start_date >= DATE '2020-01-01'
      AND ws.web_rec_end_date <= DATE '2025-12-31'
      AND cd.cd_purchase_estimate >= 1500
    GROUP BY ws.web_site_id, ws.web_name, cd.cd_education_status
)
SELECT
    web_site_id,
    web_name,
    cd_education_status,
    num_customers,
    total_purchase_estimate,
    avg_purchase_estimate,
    total_vehicles,
    avg_vehicles,
    total_dependents,
    avg_employed_dependents,
    RANK() OVER (PARTITION BY cd_education_status ORDER BY total_purchase_estimate DESC) AS purchase_rank
FROM agg
ORDER BY total_purchase_estimate DESC
LIMIT 100
