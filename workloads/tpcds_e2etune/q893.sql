SELECT
    i.i_category,
    sm.sm_type,
    COUNT(DISTINCT i.i_item_sk) AS distinct_items,
    SUM(i.i_wholesale_cost) AS total_wholesale_cost,
    AVG(i.i_current_price) AS avg_current_price,
    MIN(i.i_rec_start_date) AS earliest_rec_start,
    MAX(i.i_rec_end_date) AS latest_rec_end,
    approx_percentile(i.i_wholesale_cost, 0.5) AS median_wholesale_cost
FROM
    item i
JOIN
    ship_mode sm
    ON substr(i.i_item_id, 1, 8) = sm.sm_ship_mode_id
WHERE
    i.i_rec_start_date >= DATE '2000-01-01'
    AND i.i_color = 'red'
    AND sm.sm_carrier = 'UPS'
GROUP BY
    i.i_category,
    sm.sm_type
HAVING
    COUNT(*) > 100
ORDER BY
    total_wholesale_cost DESC,
    avg_current_price ASC
LIMIT 100
