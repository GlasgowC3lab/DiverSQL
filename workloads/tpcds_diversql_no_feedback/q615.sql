WITH sales_page_agg AS (
    SELECT
        cp.cp_department AS department,
        t.t_shift AS shift,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(*) AS txn_count,
        AVG(cs.cs_wholesale_cost) AS avg_wholesale_cost
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_end_date_sk BETWEEN 2450874 AND 2451361
      AND t.t_shift = 'first'
    GROUP BY cp.cp_department, t.t_shift
)
SELECT
    department,
    shift,
    total_sales,
    total_quantity,
    txn_count,
    avg_wholesale_cost,
    total_sales - LAG(total_sales) OVER (PARTITION BY department ORDER BY total_sales DESC) AS sales_lag_diff,
    total_sales / (SELECT SUM(cs_ext_sales_price) FROM catalog_sales) AS sales_share
FROM sales_page_agg
WHERE total_sales > (SELECT AVG(total_sales) FROM sales_page_agg)
ORDER BY total_sales DESC
LIMIT 100
