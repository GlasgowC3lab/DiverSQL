WITH base AS (
    SELECT
        hd.hd_income_band_sk,
        sm.sm_type,
        ws.web_state,
        COUNT(*) AS demo_count,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
        SUM(wp.wp_link_count) AS total_links,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages
    FROM household_demographics hd
    JOIN ship_mode sm ON hd.hd_demo_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON hd.hd_demo_sk = wp.wp_web_page_sk
    JOIN web_site ws ON sm.sm_ship_mode_sk = ws.web_site_sk
    WHERE hd.hd_buy_potential = '1001-5000'
      AND sm.sm_contract = 'YvxVaJI10'
      AND wp.wp_type = 'home'
    GROUP BY hd.hd_income_band_sk, sm.sm_type, ws.web_state
    HAVING SUM(wp.wp_link_count) > 1000
)
SELECT
    hd_income_band_sk,
    sm_type,
    web_state,
    demo_count,
    avg_vehicle_count,
    total_links,
    distinct_pages,
    RANK() OVER (PARTITION BY web_state ORDER BY total_links DESC) AS state_link_rank
FROM base
ORDER BY avg_vehicle_count DESC
LIMIT 100
