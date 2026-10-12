SELECT
    sm.sm_carrier,
    sm.sm_type,
    s.s_store_name,
    s.s_state,
    sold_d.d_year AS sold_year,
    ship_d.d_year AS ship_year,
    COUNT(DISTINCT cs.cs_order_number) AS orders,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_net_profit) AS avg_profit,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    COUNT(DISTINCT wp.wp_web_page_sk) AS web_pages_created,
    MAX(wp.wp_url) FILTER (WHERE wp.wp_type = 'homepage') AS homepage_url
FROM catalog_sales cs
JOIN date_dim sold_d
    ON cs.cs_sold_date_sk = sold_d.d_date_sk
JOIN date_dim ship_d
    ON cs.cs_ship_date_sk = ship_d.d_date_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store s
    ON s.s_closed_date_sk = sold_d.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = sold_d.d_date_sk
WHERE sold_d.d_year = 2022
  AND sm.sm_carrier LIKE '%UPS%'
GROUP BY
    sm.sm_carrier,
    sm.sm_type,
    s.s_store_name,
    s.s_state,
    sold_d.d_year,
    ship_d.d_year
HAVING SUM(cs.cs_ext_sales_price) > 5000
ORDER BY total_sales DESC
LIMIT 100
