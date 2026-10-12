WITH sales_agg AS (
    SELECT
        s.s_store_sk AS s_store_sk,
        s.s_store_name AS s_store_name,
        s.s_state AS s_state,
        cd_bill.cd_gender AS bill_gender,
        cd_bill.cd_education_status AS bill_education,
        cd_ship.cd_gender AS ship_gender,
        cd_ship.cd_education_status AS ship_education,
        d_sold.d_year AS sold_year,
        d_sold.d_month_seq AS sold_month,
        d_ship.d_year AS ship_year,
        d_ship.d_month_seq AS ship_month,
        SUM(cs.cs_net_paid) AS total_net_paid,
        AVG(cs.cs_net_profit) AS avg_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_days_to_ship,
        AVG(date_diff('day', d_sold.d_date, d_wp_access.d_date)) AS avg_wp_access_delay,
        MIN(wp.wp_url) AS sample_url
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_sold.d_date_sk
    JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        cd_bill.cd_gender,
        cd_bill.cd_education_status,
        cd_ship.cd_gender,
        cd_ship.cd_education_status,
        d_sold.d_year,
        d_sold.d_month_seq,
        d_ship.d_year,
        d_ship.d_month_seq
)
SELECT
    s_store_sk,
    s_store_name,
    s_state,
    bill_gender,
    bill_education,
    ship_gender,
    ship_education,
    sold_year,
    sold_month,
    ship_year,
    ship_month,
    total_net_paid,
    avg_net_profit,
    order_cnt,
    avg_days_to_ship,
    avg_wp_access_delay,
    sample_url,
    ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY total_net_paid DESC) AS rank_by_store
FROM sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
