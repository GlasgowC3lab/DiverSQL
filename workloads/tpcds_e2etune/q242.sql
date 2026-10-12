WITH store_agg AS (
    SELECT
        s_state,
        COUNT(*) AS store_cnt,
        AVG(s_floor_space) AS avg_floor_space
    FROM store
    WHERE s_rec_start_date >= DATE '2020-01-01'
      AND (s_rec_end_date IS NULL OR s_rec_end_date > CURRENT_DATE)
    GROUP BY s_state
    HAVING COUNT(*) > 5
),
ship_mode_agg AS (
    SELECT
        sm_type,
        COUNT(*) AS mode_cnt,
        AVG(sm_ship_mode_sk) AS avg_sk
    FROM ship_mode
    WHERE sm_type IN ('EXPRESS', 'OVERNIGHT', 'TWO DAY')
    GROUP BY sm_type
),
web_page_agg AS (
    SELECT
        wp_type,
        COUNT(*) AS page_cnt,
        AVG(wp_char_count) AS avg_char
    FROM web_page
    WHERE wp_rec_start_date >= DATE '2022-01-01'
    GROUP BY wp_type
)
SELECT
    s.s_state,
    s.store_cnt,
    s.avg_floor_space,
    sm.sm_type,
    sm.mode_cnt,
    sm.avg_sk,
    wp.wp_type,
    wp.page_cnt,
    wp.avg_char,
    ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY sm.mode_cnt DESC) AS rn
FROM store_agg s
JOIN ship_mode_agg sm
    ON (CAST(s.store_cnt AS BIGINT) % 5) = (CAST(sm.mode_cnt AS BIGINT) % 5)
JOIN web_page_agg wp
    ON (CAST(s.avg_floor_space AS BIGINT) % 10) = (CAST(wp.page_cnt AS BIGINT) % 10)
WHERE s.avg_floor_space > 1000
ORDER BY s.store_cnt DESC, wp.page_cnt ASC
LIMIT 100
