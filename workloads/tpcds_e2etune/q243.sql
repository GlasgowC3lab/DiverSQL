WITH agg AS (
    SELECT
        cp.cp_department,
        sm.sm_carrier,
        ib.ib_income_band_sk,
        COUNT(DISTINCT i.i_item_sk) AS distinct_items,
        AVG(i.i_current_price) AS avg_price,
        SUM(i.i_wholesale_cost) AS total_wholesale
    FROM catalog_page cp
    JOIN ship_mode sm
        ON cp.cp_type = sm.sm_type
    JOIN item i
        ON i.i_category = cp.cp_department
    JOIN income_band ib
        ON CAST(i.i_current_price AS INTEGER) BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE cp.cp_start_date_sk BETWEEN 2450800 AND 2451100
      AND cp.cp_end_date_sk   BETWEEN 2450900 AND 2451200
      AND sm.sm_ship_mode_id IS NOT NULL
    GROUP BY cp.cp_department, sm.sm_carrier, ib.ib_income_band_sk
    HAVING COUNT(DISTINCT i.i_item_sk) > 5
)
SELECT
    *,
    RANK() OVER (PARTITION BY cp_department ORDER BY avg_price DESC) AS price_rank
FROM agg
ORDER BY cp_department, price_rank
