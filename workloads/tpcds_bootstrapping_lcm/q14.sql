SELECT
    cs.cs_item_sk,
    cust.c_birth_month,
    (cust.c_birth_month % 3) AS birth_month_mod3,
    d_sold.d_year AS sold_year,
    d_ship.d_year AS ship_year,
    s.s_state,
    wp.wp_type,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid), 0) AS profit_margin,
    MAX(wp.wp_image_count) AS max_image_count,
    MIN(wp.wp_char_count) AS min_char_count,
    SUM(CASE WHEN cs.cs_coupon_amt > 0 THEN cs.cs_coupon_amt ELSE 0 END) AS total_coupon_amt,
    COUNT(*) FILTER (WHERE d_store.d_year = 2020) AS store_closed_2020_cnt,
    COUNT(*) FILTER (WHERE d_wp_creation.d_year = 2020) AS wp_created_2020_cnt,
    COUNT(*) FILTER (WHERE d_wp_access.d_year = 2020) AS wp_accessed_2020_cnt,
    COUNT(*) FILTER (WHERE cust_ship.c_birth_country = 'USA') AS shipping_us_customers
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer cust
    ON cs.cs_bill_customer_sk = cust.c_customer_sk
JOIN customer cust_ship
    ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
JOIN date_dim d_first_shipto
    ON cust.c_first_shipto_date_sk = d_first_shipto.d_date_sk
JOIN date_dim d_first_sales
    ON cust.c_first_sales_date_sk = d_first_sales.d_date_sk
JOIN date_dim d_last_review
    ON cust.c_last_review_date = d_last_review.d_date_sk
JOIN date_dim d_store
    ON cs.cs_sold_date_sk = d_store.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN web_page wp
    ON wp.wp_customer_sk = cust.c_customer_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_sold.d_year = 2020
  AND s.s_state IN ('CA', 'NY', 'TX')
  AND wp.wp_type = 'article'
GROUP BY
    cs.cs_item_sk,
    cust.c_birth_month,
    (cust.c_birth_month % 3),
    d_sold.d_year,
    d_ship.d_year,
    s.s_state,
    wp.wp_type
HAVING COUNT(*) > 10
ORDER BY total_net_paid DESC
LIMIT 100
