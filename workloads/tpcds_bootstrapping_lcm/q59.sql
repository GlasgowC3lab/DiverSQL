SELECT
    s.s_store_name,
    i.i_category,
    d_sold.d_year,
    d_ship.d_month_seq,
    COUNT(DISTINCT cs.cs_order_number)           AS distinct_orders,
    SUM(cs.cs_net_paid)                         AS total_net_paid,
    SUM(cs.cs_ext_discount_amt)                 AS total_discount,
    AVG(cs.cs_net_profit)                       AS avg_profit,
    SUM(cs.cs_net_paid * cs.cs_quantity)        AS revenue_quantity_product,
    SUM(CASE WHEN wp.wp_type = 'Landing' THEN cs.cs_ext_sales_price ELSE 0 END) AS landing_page_sales,
    SUM(CASE WHEN d_sold.d_day_name IN ('Saturday','Sunday') THEN cs.cs_net_paid ELSE 0 END) AS weekend_net_paid,
    (SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid), 0)) AS profit_margin,
    MAX(cs.cs_sales_price)                      AS max_sales_price
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE
    d_sold.d_year = 2023
    AND i.i_category = 'Sports'
    AND s.s_state = 'TX'
GROUP BY
    s.s_store_name,
    i.i_category,
    d_sold.d_year,
    d_ship.d_month_seq
HAVING
    SUM(cs.cs_net_paid) > 5000
ORDER BY
    total_net_paid DESC
LIMIT 50
