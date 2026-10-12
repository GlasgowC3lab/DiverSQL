WITH agg AS (
    SELECT
        cd.cd_education_status,
        hd.hd_buy_potential,
        COUNT(*) AS num_customers,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd.cd_dep_employed_count) AS avg_dep_employed,
        COUNT(DISTINCT hd.hd_income_band_sk) AS distinct_income_bands
    FROM
        customer_demographics cd
    JOIN
        household_demographics hd
        ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE
        cd.cd_credit_rating = 'Good'
        AND hd.hd_vehicle_count >= 2
        AND cd.cd_purchase_estimate >= 1000
    GROUP BY
        cd.cd_education_status,
        hd.hd_buy_potential
    HAVING
        SUM(cd.cd_purchase_estimate) > 5000
)
SELECT
    cd_education_status,
    hd_buy_potential,
    num_customers,
    total_purchase_estimate,
    avg_dep_employed,
    distinct_income_bands,
    RANK() OVER (PARTITION BY hd_buy_potential ORDER BY total_purchase_estimate DESC) AS education_rank_within_buy_potential
FROM
    agg
ORDER BY
    total_purchase_estimate DESC
LIMIT 20
