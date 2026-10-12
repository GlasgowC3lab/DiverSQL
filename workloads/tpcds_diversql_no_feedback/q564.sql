WITH store_sales_agg AS (
    SELECT
        d.d_year AS year,
        s.s_store_name AS category,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_amount,
        'Store Sales' AS metric_type
    FROM store s
    FULL OUTER JOIN store_sales ss
        ON s.s_store_sk = ss.ss_store_sk
    LEFT JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002 OR d.d_year IS NULL
    GROUP BY d.d_year, s.s_store_name
),
catalog_sales_agg AS (
    SELECT
        d.d_year AS year,
        sm.sm_type AS category,
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_amount,
        'Catalog Sales' AS metric_type
    FROM catalog_sales cs
    RIGHT OUTER JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type = 'AIR' OR sm.sm_type IS NULL
    GROUP BY d.d_year, sm.sm_type
)
SELECT *
FROM store_sales_agg
UNION ALL
SELECT *
FROM catalog_sales_agg
ORDER BY year DESC, total_amount DESC
LIMIT 100
