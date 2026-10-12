WITH page_stats AS (
    SELECT
        wp_customer_sk,
        COUNT(*) AS page_cnt,
        SUM(wp_char_count) AS total_char,
        MAX(CASE WHEN wp_autogen_flag = 'Y' THEN 1 ELSE 0 END) AS has_autogen
    FROM web_page
    WHERE wp_rec_start_date >= DATE '1999-01-01'
      AND wp_rec_start_date <= DATE '2002-12-31'
      AND wp_autogen_flag IN ('Y', 'N')
    GROUP BY wp_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_birth_year,
    hd.hd_income_band_sk,
    hd.hd_vehicle_count,
    ps.page_cnt,
    ps.total_char,
    CASE
        WHEN hd.hd_vehicle_count >= 2 THEN 'Multiple Vehicles'
        WHEN hd.hd_vehicle_count = 1 THEN 'One Vehicle'
        ELSE 'No Vehicle'
    END AS vehicle_category,
    (ps.total_char * 1.0) / NULLIF(ps.page_cnt, 0) AS avg_chars_per_page
FROM customer c
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN page_stats ps
    ON ps.wp_customer_sk = c.c_customer_sk
WHERE c.c_birth_year BETWEEN 1950 AND 2000
  AND c.c_birth_country IN ('KOREA', 'CHILE', 'JORDAN')
  AND hd.hd_income_band_sk IN (5, 11, 15)
  AND hd.hd_vehicle_count >= 0
  AND ps.has_autogen = 1
GROUP BY
    c.c_customer_id,
    c.c_birth_year,
    hd.hd_income_band_sk,
    hd.hd_vehicle_count,
    ps.page_cnt,
    ps.total_char,
    CASE
        WHEN hd.hd_vehicle_count >= 2 THEN 'Multiple Vehicles'
        WHEN hd.hd_vehicle_count = 1 THEN 'One Vehicle'
        ELSE 'No Vehicle'
    END
HAVING SUM(ps.total_char) > 1000
ORDER BY avg_chars_per_page DESC
LIMIT 100
