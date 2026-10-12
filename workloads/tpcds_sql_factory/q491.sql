WITH ship_stats AS (
    SELECT
        cs.cs_warehouse_sk,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_revenue,
        SUM(cs.cs_ext_ship_cost) AS total_ship_cost
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_ship_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2022
    GROUP BY cs.cs_warehouse_sk, d.d_year, d.d_month_seq
)
SELECT
    cs_warehouse_sk,
    d_year,
    d_month_seq,
    total_quantity,
    total_revenue,
    total_ship_cost,
    CASE WHEN total_revenue = 0 THEN 0 ELSE total_quantity / total_revenue END AS quantity_per_dollar,
    CASE
        WHEN total_quantity / total_revenue < 0.01 THEN 'Very Low'
        WHEN total_quantity / total_revenue < 0.03 THEN 'Low'
        WHEN total_quantity / total_revenue < 0.06 THEN 'Medium'
        ELSE 'High'
    END AS efficiency_category,
    warehouse_rank
FROM (
    SELECT
        cs_warehouse_sk,
        d_year,
        d_month_seq,
        total_quantity,
        total_revenue,
        total_ship_cost,
        ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_quantity DESC) AS warehouse_rank
    FROM ship_stats
) ranked
WHERE warehouse_rank <= 5
ORDER BY d_year, d_month_seq, warehouse_rank
