SELECT
    s.s_city,
    s.s_state,
    wp.wp_type,
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month_seq,
    d_ship.d_month_seq AS ship_month_seq,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_net_profit) AS total_profit,
    CASE
        WHEN SUM(cs.cs_ext_sales_price) > 0 THEN SUM(cs.cs_net_profit) / SUM(cs.cs_ext_sales_price)
        ELSE 0
    END AS profit_margin,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    MAX(wp.wp_image_count) AS max_image_count,
    MIN(d_store.d_date) AS store_closed_date,
    MAX(d_creation.d_date) AS web_page_creation_date,
    MAX(d_access.d_date) AS web_page_access_date,
    SUM(CASE WHEN cs.cs_quantity > 1 THEN cs.cs_net_paid ELSE 0 END) AS net_paid_multi_qty,
    SUM(CASE WHEN cs.cs_coupon_amt > 0 THEN cs.cs_coupon_amt ELSE 0 END) AS total_coupon_amount
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
CROSS JOIN store s
JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
CROSS JOIN web_page wp
JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE cs.cs_net_paid > 0
  AND s.s_state IS NOT NULL
  AND wp.wp_type IS NOT NULL
GROUP BY
    s.s_city,
    s.s_state,
    wp.wp_type,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_month_seq
ORDER BY total_net_paid DESC
LIMIT 100
