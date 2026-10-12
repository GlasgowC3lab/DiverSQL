WITH sales_agg AS (
    SELECT
        s.s_store_name,
        s.s_city,
        s.s_state,
        ca.ca_city AS cust_city,
        ca.ca_state AS cust_state,
        d_sold.d_year,
        d_sold.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        SUM(ss.ss_quantity) AS total_quantity,
        MIN(wp.wp_image_count) AS min_image_count,
        MAX(wp.wp_image_count) AS max_image_count,
        SUM(CASE WHEN wp.wp_type = 'product' THEN wp.wp_link_count ELSE 0 END) AS product_page_links
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_closed.d_date_sk
    JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE d_sold.d_year = 2022
    GROUP BY s.s_store_name, s.s_city, s.s_state, ca.ca_city, ca.ca_state, d_sold.d_year, d_sold.d_month_seq
    HAVING SUM(ss.ss_ext_sales_price) > 5000
)
SELECT
    s_store_name,
    s_city,
    s_state,
    cust_city,
    cust_state,
    d_year,
    d_month_seq,
    total_sales,
    total_profit,
    avg_discount,
    distinct_customers,
    total_quantity,
    min_image_count,
    max_image_count,
    product_page_links,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank_year
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
