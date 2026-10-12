WITH sampled_returns AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)   -- sample 10% of rows
),

filtered_returns AS (
    SELECT *
    FROM sampled_returns
    WHERE cr_return_amount > 100                     -- predicate 1
      AND cr_return_quantity >= 1                    -- predicate 2
      AND cr_warehouse_sk IN (1, 4, 11)              -- predicate 3
      AND cr_store_credit < 120                      -- predicate 4
      AND cr_order_number NOT IN (
            SELECT cr_order_number
            FROM catalog_returns
            WHERE cr_return_amount > 4000
        )                                           -- predicate 5 (anti‑semi‑join)
),

intersect_orders AS (
    SELECT cr_order_number
    FROM catalog_returns
    WHERE cr_warehouse_sk = 1
    INTERSECT
    SELECT cr_order_number
    FROM catalog_returns
    WHERE cr_store_credit > 50
),

joined AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_warehouse_sk,
        cr.cr_store_credit,
        cr.cr_return_amt_inc_tax,
        cr.cr_order_number,
        cp.cp_department,
        cp.cp_type,
        cp.cp_description,
        cp.cp_end_date_sk
    FROM filtered_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_end_date_sk BETWEEN 2450900 AND 2451080          -- predicate 6
      AND cp.cp_description LIKE '%goods%'                     -- predicate 7
),

joined_filtered AS (
    SELECT j.*
    FROM joined j
    JOIN intersect_orders io ON j.cr_order_number = io.cr_order_number
),

agg_per_type AS (
    SELECT
        cp_department,
        cp_type,
        SUM(cr_return_amount) AS sum_return_amount,
        SUM(cr_return_quantity) AS sum_quantity,
        COUNT(*) AS cnt_returns,
        CASE
            WHEN cp_department = 'Women' THEN 'W'
            ELSE 'Other'
        END AS dept_group
    FROM joined_filtered
    GROUP BY cp_department, cp_type,
        CASE WHEN cp_department = 'Women' THEN 'W' ELSE 'Other' END
),

final_agg AS (
    SELECT
        dept_group,
        AVG(sum_return_amount) AS avg_sum_return_amount,
        SUM(cnt_returns) AS total_returns,
        SUM(sum_quantity) AS total_quantity
    FROM agg_per_type
    WHERE cp_type IS NOT NULL
    GROUP BY dept_group
    HAVING AVG(sum_return_amount) > 500
)
SELECT
    dept_group,
    avg_sum_return_amount,
    total_returns,
    total_quantity
FROM final_agg
ORDER BY avg_sum_return_amount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
