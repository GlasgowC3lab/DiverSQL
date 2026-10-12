WITH base AS (
    SELECT
        s.s_state,
        i.i_category,
        COUNT(DISTINCT i.i_item_sk) AS distinct_item_cnt,
        AVG(i.i_current_price) AS avg_price,
        MIN(i.i_current_price) AS min_price,
        MAX(i.i_current_price) AS max_price,
        SUM(i.i_wholesale_cost) AS total_wholesale_cost,
        approx_percentile(i.i_current_price, 0.5) AS median_price,
        COUNT(DISTINCT r.r_reason_id) AS distinct_reason_cnt,
        COUNT(DISTINCT sm.sm_ship_mode_id) AS distinct_ship_mode_cnt
    FROM
        store s
        JOIN warehouse w
            ON s.s_state = w.w_state
            AND s.s_zip = w.w_zip
        JOIN item i
            ON i.i_brand_id = s.s_market_id
        JOIN catalog_page cp
            ON cp.cp_department = i.i_category
            AND cp.cp_type = 'quarterly'
            AND cp.cp_end_date_sk BETWEEN 2450900 AND 2451100
            AND cp.cp_description LIKE '%public%'
        JOIN reason r
            ON r.r_reason_desc IS NOT NULL
        JOIN ship_mode sm
            ON r.r_reason_id = sm.sm_ship_mode_id
    WHERE
        i.i_units = 'EA'
        AND i.i_current_price > 20
    GROUP BY
        s.s_state,
        i.i_category
    HAVING
        COUNT(DISTINCT i.i_item_sk) > 5
)
SELECT
    s_state,
    i_category,
    distinct_item_cnt,
    avg_price,
    min_price,
    max_price,
    total_wholesale_cost,
    median_price,
    distinct_reason_cnt,
    distinct_ship_mode_cnt,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY avg_price DESC) AS price_rank_by_state
FROM
    base
ORDER BY
    s_state,
    price_rank_by_state
