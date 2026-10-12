WITH hd_agg AS (
    SELECT
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        COUNT(*) AS household_cnt,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt,
        SUM(hd.hd_dep_count) AS total_dep_cnt
    FROM household_demographics hd
    WHERE hd.hd_income_band_sk BETWEEN 2 AND 5
    GROUP BY hd.hd_buy_potential, hd.hd_income_band_sk
),
wp_agg AS (
    SELECT
        wp.wp_type,
        COUNT(*) AS page_cnt,
        AVG(wp.wp_image_count) AS avg_image_cnt,
        SUM(CASE WHEN wp.wp_image_count > 3 THEN 1 ELSE 0 END) AS high_image_pages
    FROM web_page wp
    WHERE wp.wp_image_count IS NOT NULL
    GROUP BY wp.wp_type
)
SELECT
    hd_agg.hd_buy_potential,
    hd_agg.hd_income_band_sk,
    hd_agg.household_cnt,
    hd_agg.avg_vehicle_cnt,
    wp_agg.wp_type,
    wp_agg.page_cnt,
    wp_agg.avg_image_cnt,
    hd_agg.total_dep_cnt + wp_agg.high_image_pages AS combined_metric
FROM hd_agg
JOIN wp_agg ON true
WHERE hd_agg.household_cnt > 10
  AND wp_agg.page_cnt > 5
ORDER BY combined_metric DESC
LIMIT 50
