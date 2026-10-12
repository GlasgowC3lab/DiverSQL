/* goal: Identify high‑value catalog page returns, ranking them within each department and showing warehouse context, using a full outer join, lateral aggregation, window ranking, CASE logic, and a scalar subquery. */
WITH page_returns AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_number,
        cp.cp_department,
        cp.cp_description,
        cr.cr_return_amount,
        cr.cr_return_ship_cost,
        cr.cr_store_credit,
        cr.cr_ship_mode_sk,
        cr.cr_warehouse_sk,
        w.w_warehouse_name,
        w.w_county,
        /* ranking within each department by return amount */
        ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY cr.cr_return_amount DESC) AS dept_return_rank,
        /* credit level flag */
        CASE WHEN cr.cr_store_credit > 50 THEN 'High' ELSE 'Low' END AS credit_level,
        /* average return amount for the warehouse (scalar subquery) */
        (
            SELECT AVG(cr3.cr_return_amount)
            FROM catalog_returns cr3
            WHERE cr3.cr_warehouse_sk = cr.cr_warehouse_sk
        ) AS avg_return_amt_warehouse
    FROM catalog_page cp
    FULL OUTER JOIN catalog_returns cr
        ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE
        cp.cp_catalog_number IN (1, 6, 12, 17)               -- predicate 1
        AND cr.cr_return_ship_cost > 100                     -- predicate 2
        AND w.w_county = 'Bronx County'                      -- predicate 3
        AND cr.cr_ship_mode_sk BETWEEN 9 AND 15              -- predicate 4
        AND cp.cp_end_date_sk > 2451000                      -- predicate 5
),
-- LATERAL subquery to compute total return amount per catalog page
page_returns_lateral AS (
    SELECT
        pr.*,
        lr.total_page_return_amount
    FROM page_returns pr
    LEFT JOIN LATERAL (
        SELECT SUM(cr2.cr_return_amount) AS total_page_return_amount
        FROM catalog_returns cr2
        WHERE cr2.cr_catalog_page_sk = pr.cp_catalog_page_sk
    ) lr ON TRUE
)
SELECT
    cp_catalog_page_sk,
    cp_catalog_number,
    cp_department,
    cp_description,
    cr_return_amount,
    cr_return_ship_cost,
    cr_store_credit,
    credit_level,
    dept_return_rank,
    w_warehouse_name,
    w_county,
    total_page_return_amount,
    avg_return_amt_warehouse
FROM page_returns_lateral
WHERE dept_return_rank <= 5
ORDER BY cp_department, dept_return_rank
LIMIT 100
