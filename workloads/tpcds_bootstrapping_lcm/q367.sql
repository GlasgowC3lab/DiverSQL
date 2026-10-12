SELECT
    d_sold.d_year AS sold_year,
    d_ship.d_month_seq AS ship_month_seq,
    ca_bill.ca_state AS bill_state,
    CASE WHEN ca_ship.ca_country = 'United States' THEN 'Domestic' ELSE 'International' END AS ship_region,
    s.s_market_desc,
    wp.wp_type,
    COUNT(*) AS order_cnt,
    SUM(cs.cs_ext_sales_price) AS total_sales_price,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    SUM(CASE WHEN cs.cs_coupon_amt > 0 THEN cs.cs_coupon_amt ELSE 0 END) AS total_coupon_amount
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
    AND wp.wp_access_date_sk = d_ship.d_date_sk
GROUP BY
    d_sold.d_year,
    d_ship.d_month_seq,
    ca_bill.ca_state,
    CASE WHEN ca_ship.ca_country = 'United States' THEN 'Domestic' ELSE 'International' END,
    s.s_market_desc,
    wp.wp_type
HAVING COUNT(*) > 5
ORDER BY total_sales_price DESC
LIMIT 100
