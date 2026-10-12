WITH store_sales_agg AS (
    SELECT
        d.d_date AS sale_date,
        s.s_store_name AS category,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt,
        'Store' AS source
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
    GROUP BY d.d_date, s.s_store_name
),
catalog_sales_agg AS (
    SELECT
        d.d_date AS sale_date,
        cp.cp_department AS category,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt,
        'Catalog' AS source
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND cp.cp_type = 'Standard'
    GROUP BY d.d_date, cp.cp_department
)
SELECT
    u.sale_date,
    u.category,
    u.total_net_paid,
    u.sales_cnt,
    u.source,
    SUM(u.total_net_paid) OVER (ORDER BY u.sale_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
) AS u
ORDER BY u.sale_date, u.total_net_paid DESC
LIMIT 100
