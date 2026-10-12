SELECT
    d_sold.d_year AS sale_year,
    d_ship.d_year AS ship_year,
    d_wp_access.d_year AS access_year,
    s.s_state,
    wp.wp_type,
    COUNT(*) AS row_cnt,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_sales_price) AS total_sales_price,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(cs.cs_quantity) AS avg_quantity,
    SUM(cs.cs_net_paid) FILTER (WHERE cs.cs_coupon_amt > 0) AS net_paid_with_coupon,
    SUM(cs.cs_net_paid - cs.cs_ext_tax) AS net_paid_excl_tax,
    (SUM(cs.cs_ext_sales_price) - SUM(cs.cs_ext_discount_amt) - SUM(cs.cs_ext_tax)) / NULLIF(SUM(cs.cs_ext_sales_price), 0) AS net_margin_ratio,
    CASE
        WHEN d_sold.d_month_seq BETWEEN 1 AND 6 THEN 'H1'
        ELSE 'H2'
    END AS half_year,
    (SUM(cs.cs_net_paid) * 0.1) AS ten_percent_of_net_paid
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_sold.d_year >= 2000
    AND s.s_state IS NOT NULL
    AND wp.wp_type IS NOT NULL
GROUP BY
    d_sold.d_year,
    d_ship.d_year,
    d_wp_access.d_year,
    s.s_state,
    wp.wp_type,
    CASE
        WHEN d_sold.d_month_seq BETWEEN 1 AND 6 THEN 'H1'
        ELSE 'H2'
    END
