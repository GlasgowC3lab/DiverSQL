SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    s.s_city,
    CASE 
        WHEN s.s_state IN ('CA','OR','WA','NV','AZ') THEN 'West'
        WHEN s.s_state IN ('NY','NJ','CT','MA','PA') THEN 'East'
        ELSE 'Other'
    END AS region,
    d.d_year,
    d.d_current_month,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(cs.cs_ext_discount_amt) AS total_catalog_discount,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(ss.ss_ext_discount_amt) AS total_store_discount,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages_accessed,
    COUNT(DISTINCT wp.wp_type) AS distinct_page_types,
    CASE 
        WHEN (SUM(cs.cs_net_paid) + SUM(ss.ss_net_paid)) > 50000 THEN 'HIGH'
        ELSE 'LOW'
    END AS revenue_category,
    ROUND(
        (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit)) / NULLIF((SUM(cs.cs_net_paid) + SUM(ss.ss_net_paid)), 0) * 100,
        2
    ) AS overall_profit_margin_percent
FROM store_sales ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
LEFT JOIN web_page wp
    ON wp.wp_access_date_sk = d.d_date_sk
LEFT JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
LEFT JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
LEFT JOIN date_dim d_cs_ship
    ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
WHERE d.d_year = 2022
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    s.s_city,
    CASE 
        WHEN s.s_state IN ('CA','OR','WA','NV','AZ') THEN 'West'
        WHEN s.s_state IN ('NY','NJ','CT','MA','PA') THEN 'East'
        ELSE 'Other'
    END,
    d.d_year,
    d.d_current_month
ORDER BY total_store_net_paid DESC
LIMIT 100
