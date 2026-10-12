WITH store_sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_sold.d_year AS sold_year,
        d_ship.d_month_seq AS ship_month_seq,
        cd_bill.cd_gender AS bill_gender,
        cd_ship.cd_gender AS ship_gender,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        AVG(cs.cs_quantity) AS avg_quantity,
        AVG(wp.wp_image_count) AS avg_image_count,
        MAX(wp.wp_max_ad_count) AS max_ad_count,
        d_wp_access.d_day_name AS access_day_name
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
    JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    WHERE d_sold.d_year BETWEEN 2018 AND 2020
      AND s.s_state = 'CA'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d_sold.d_year,
        d_ship.d_month_seq,
        cd_bill.cd_gender,
        cd_ship.cd_gender,
        d_wp_access.d_day_name
)
SELECT
    s_store_id,
    s_store_name,
    sold_year,
    ship_month_seq,
    bill_gender,
    ship_gender,
    order_count,
    total_net_paid,
    total_discount,
    avg_quantity,
    avg_image_count,
    max_ad_count,
    access_day_name,
    ROW_NUMBER() OVER (PARTITION BY s_store_id, sold_year ORDER BY total_net_paid DESC) AS store_year_rank
FROM store_sales
ORDER BY total_net_paid DESC
LIMIT 50
