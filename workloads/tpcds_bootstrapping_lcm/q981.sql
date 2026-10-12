WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d_sold.d_year AS sold_year,
        d_sold.d_month_seq AS sold_month_seq,
        wp.wp_type,
        cd_bill.cd_credit_rating AS bill_credit_rating,
        cd_ship.cd_credit_rating AS ship_credit_rating,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_bill_customers,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS distinct_ship_customers
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ship.d_date_sk
    WHERE d_sold.d_year >= 2020
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d_sold.d_year,
        d_sold.d_month_seq,
        wp.wp_type,
        cd_bill.cd_credit_rating,
        cd_ship.cd_credit_rating
)
SELECT
    s_store_id,
    s_store_name,
    s_state,
    sold_year,
    sold_month_seq,
    wp_type,
    bill_credit_rating,
    ship_credit_rating,
    total_net_paid,
    total_sales,
    total_net_profit,
    distinct_bill_customers,
    distinct_ship_customers,
    ROW_NUMBER() OVER (PARTITION BY sold_year ORDER BY total_net_profit DESC) AS profit_rank_by_year
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 100
