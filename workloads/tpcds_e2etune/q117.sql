WITH cd_agg AS (
    SELECT
        cd_education_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_employed_count) AS total_dep_employed,
        COUNT(*) AS cd_cnt,
        substr(cd_education_status, 1, 1) AS edu_initial
    FROM customer_demographics
    WHERE cd_purchase_estimate >= 1500
      AND cd_education_status IS NOT NULL
    GROUP BY cd_education_status
),
ws_agg AS (
    SELECT
        web_state,
        AVG(web_gmt_offset) AS avg_gmt_offset,
        COUNT(*) AS site_cnt,
        substr(web_state, 1, 1) AS state_initial
    FROM web_site
    WHERE web_state IS NOT NULL
    GROUP BY web_state
),
joined AS (
    SELECT
        cd.cd_education_status,
        cd.avg_purchase_estimate,
        cd.total_dep_employed,
        ws.web_state,
        ws.avg_gmt_offset,
        ws.site_cnt
    FROM cd_agg cd
    JOIN ws_agg ws
      ON cd.edu_initial = ws.state_initial
    WHERE cd.avg_purchase_estimate > 1800
)
SELECT
    cd_education_status,
    avg_purchase_estimate,
    total_dep_employed,
    web_state,
    avg_gmt_offset,
    site_cnt,
    RANK() OVER (ORDER BY avg_purchase_estimate DESC) AS purchase_rank
FROM joined
ORDER BY purchase_rank ASC, site_cnt DESC
LIMIT 100
