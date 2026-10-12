WITH base_join AS (
    SELECT
        wp.wp_web_page_id,
        wp.wp_char_count,
        wp.wp_link_count,
        wp.wp_max_ad_count,
        wp.wp_creation_date_sk,
        wp.wp_customer_sk,
        d.d_date,
        d.d_year,
        d.d_fy_quarter_seq,
        c.c_customer_id,
        hd.hd_buy_potential,
        hd.hd_dep_count
    FROM web_page wp
    RIGHT OUTER JOIN date_dim d
        ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN customer c
        ON wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE
        wp.wp_max_ad_count > 1               -- filter 1: keep pages with more than one ad slot
        AND hd.hd_dep_count <= 5              -- filter 2: households with at most 5 dependents
        AND d.d_fy_quarter_seq IN (11, 12, 14) -- filter 3: focus on specific fiscal quarters
),
agg_by_year_quarter AS (
    SELECT
        d_year AS year,
        d_fy_quarter_seq AS fy_quarter_seq,
        COUNT(DISTINCT wp_web_page_id) AS page_cnt,
        SUM(wp_link_count) AS total_links,
        AVG(wp_char_count) AS avg_char_count,
        SUM(CASE WHEN hd_buy_potential = '>10000' THEN 1 ELSE 0 END) AS high_buy_potential_cnt
    FROM base_join
    GROUP BY d_year, d_fy_quarter_seq
)
SELECT
    year,
    fy_quarter_seq,
    page_cnt,
    total_links,
    avg_char_count,
    high_buy_potential_cnt
FROM agg_by_year_quarter
WHERE
    high_buy_potential_cnt > 2   -- filter 4: at least three high‑buy‑potential households
    AND total_links > 50         -- filter 5: quarters with more than 50 total links
    AND page_cnt >= 5            -- filter 6: at least five distinct pages
ORDER BY total_links DESC
LIMIT 100
