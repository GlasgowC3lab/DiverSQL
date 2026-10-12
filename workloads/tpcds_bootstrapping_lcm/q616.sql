SELECT
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month,
    d_ship.d_year AS ship_year,
    d_ship.d_month_seq AS ship_month,
    CONCAT(cd_bill.cd_gender, '_', cd_bill.cd_marital_status) AS bill_demo,
    CONCAT(cd_ship.cd_gender, '_', cd_ship.cd_marital_status) AS ship_demo,
    s.s_state AS store_state,
    wp.wp_type AS web_page_type,
    CASE 
        WHEN cs.cs_quantity >= 10 THEN 'high'
        WHEN cs.cs_quantity >= 5 THEN 'medium'
        ELSE 'low'
    END AS quantity_bucket,
    COUNT(*) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(cs.cs_quantity) AS avg_quantity,
    SUM(CASE WHEN cs.cs_coupon_amt > 0 THEN cs.cs_coupon_amt ELSE 0 END) AS total_coupon_amt,
    SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_net_profit ELSE 0 END) AS total_profit,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_year,
    d_ship.d_month_seq,
    cd_bill.cd_gender,
    cd_bill.cd_marital_status,
    cd_ship.cd_gender,
    cd_ship.cd_marital_status,
    s.s_state,
    wp.wp_type,
    CASE 
        WHEN cs.cs_quantity >= 10 THEN 'high'
        WHEN cs.cs_quantity >= 5 THEN 'medium'
        ELSE 'low'
    END
HAVING SUM(cs.cs_net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
