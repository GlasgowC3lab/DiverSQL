SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    sm.sm_type,
    s.s_state,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_quantity) AS avg_quantity,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages,
    SUM(cs.cs_ext_sales_price) / NULLIF(SUM(cs.cs_quantity), 0) AS avg_sales_price_per_item,
    MAX(wp.wp_url) FILTER (WHERE wp.wp_type = 'Landing') AS sample_landing_url,
    SUM(CASE WHEN d_ship.d_year = d_sold.d_year THEN cs.cs_net_paid ELSE 0 END) AS net_paid_same_year_ship
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE sm.sm_type = 'AIR'
  AND d_sold.d_year BETWEEN 2020 AND 2022
  AND s.s_state IN ('CA', 'NY')
  AND wp.wp_type = 'Product'
GROUP BY d_sold.d_year, d_sold.d_month_seq, sm.sm_type, s.s_state
ORDER BY total_net_paid DESC
LIMIT 100
