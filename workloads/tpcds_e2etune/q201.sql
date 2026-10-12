SELECT
    w.w_city,
    hd.hd_buy_potential,
    COUNT(DISTINCT hd.hd_demo_sk) AS num_households,
    AVG(hd.hd_vehicle_count) AS avg_vehicles,
    SUM(w.w_warehouse_sq_ft) AS total_sqft,
    COUNT(DISTINCT wp.wp_web_page_sk) AS num_pages,
    approx_percentile(w.w_gmt_offset, 0.5) AS median_gmt_offset
FROM
    household_demographics hd
CROSS JOIN
    warehouse w
JOIN
    web_page wp ON true
WHERE
    hd.hd_income_band_sk BETWEEN 3 AND 5
    AND hd.hd_buy_potential IN ('1001-5000', '5001-10000')
    AND w.w_city IN ('Shiloh', 'Fairview')
    AND wp.wp_char_count > 500
GROUP BY
    w.w_city,
    hd.hd_buy_potential
HAVING
    COUNT(DISTINCT hd.hd_demo_sk) >= 5
ORDER BY
    total_sqft DESC,
    avg_vehicles ASC
LIMIT 100
