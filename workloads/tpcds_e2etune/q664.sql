WITH agg AS (
    SELECT
        cp.cp_department,
        i.i_brand,
        ib.ib_income_band_sk,
        COUNT(DISTINCT cp.cp_catalog_page_id) AS num_pages,
        COUNT(DISTINCT i.i_item_id) AS num_items,
        SUM(i.i_current_price) AS total_current_price,
        AVG(i.i_wholesale_cost) AS avg_wholesale_cost,
        COUNT(*) AS row_cnt
    FROM catalog_page cp
    JOIN item i
        ON cp.cp_department = i.i_category
    JOIN income_band ib
        ON i.i_wholesale_cost >= CAST(ib.ib_lower_bound AS DECIMAL(7,2))
           AND i.i_wholesale_cost < CAST(ib.ib_upper_bound AS DECIMAL(7,2))
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_start_date_sk BETWEEN 2450800 AND 2451100
      AND i.i_rec_end_date > DATE '2023-01-01'
    GROUP BY cp.cp_department, i.i_brand, ib.ib_income_band_sk
    HAVING COUNT(*) >= 10
)
SELECT
    cp_department,
    i_brand,
    ib_income_band_sk,
    num_pages,
    num_items,
    total_current_price,
    avg_wholesale_cost,
    RANK() OVER (PARTITION BY cp_department ORDER BY total_current_price DESC) AS brand_price_rank
FROM agg
ORDER BY total_current_price DESC
LIMIT 100
