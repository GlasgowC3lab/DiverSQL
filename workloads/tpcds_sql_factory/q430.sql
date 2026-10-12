WITH type_metrics AS (
    SELECT
        cp.cp_type,
        cp.cp_department,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_returning_customers
    FROM catalog_returns cr
    INNER JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    GROUP BY cp.cp_type, cp.cp_department
)
SELECT
    tm.cp_type,
    tm.cp_department,
    tm.total_return_qty,
    tm.avg_return_amount,
    tm.distinct_returning_customers,
    CASE
        WHEN tm.total_return_qty > 5000 THEN 'High Return Volume'
        WHEN tm.total_return_qty > 2000 THEN 'Medium Return Volume'
        ELSE 'Low Return Volume'
    END AS volume_category,
    PERCENT_RANK() OVER (ORDER BY tm.total_return_qty) AS qty_percentile,
    RANK() OVER (ORDER BY tm.total_return_qty DESC) AS qty_rank
FROM type_metrics tm
