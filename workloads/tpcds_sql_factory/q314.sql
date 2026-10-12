WITH monthly_category_sales AS (
    SELECT
        i.i_category,
        cs.cs_sold_date_sk AS month_id,
        SUM(cs.cs_ext_sales_price) AS monthly_sales,
        MIN(sm.sm_type) AS ship_mode
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY i.i_category, cs.cs_sold_date_sk
)
SELECT
    mc.i_category,
    mc.month_id,
    mc.monthly_sales,
    LAG(mc.monthly_sales) OVER (PARTITION BY mc.i_category ORDER BY mc.month_id) AS prior_month_sales,
    CASE
        WHEN LAG(mc.monthly_sales) OVER (PARTITION BY mc.i_category ORDER BY mc.month_id) IS NULL THEN NULL
        WHEN LAG(mc.monthly_sales) OVER (PARTITION BY mc.i_category ORDER BY mc.month_id) = 0 THEN NULL
        ELSE (mc.monthly_sales - LAG(mc.monthly_sales) OVER (PARTITION BY mc.i_category ORDER BY mc.month_id))
             / LAG(mc.monthly_sales) OVER (PARTITION BY mc.i_category ORDER BY mc.month_id) * 100
    END AS month_over_month_growth_pct,
    CASE
        WHEN mc.monthly_sales > 100000 THEN 'High'
        WHEN mc.monthly_sales BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_volume_category,
    mc.ship_mode,
    ROW_NUMBER() OVER (PARTITION BY mc.i_category ORDER BY mc.monthly_sales DESC) AS sales_rank
FROM monthly_category_sales mc
WHERE mc.monthly_sales > 0
ORDER BY mc.i_category, mc.month_id
