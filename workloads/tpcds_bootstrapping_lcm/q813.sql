WITH sales_by_store AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_addr_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS ticket_cnt
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_addr_sk, ss.ss_sold_date_sk
)
SELECT
    ca.ca_city,
    ca.ca_state,
    d_sales.d_year,
    d_closed.d_current_month,
    s.s_store_name,
    s.s_market_desc,
    wp.wp_type,
    sb.total_sales,
    sb.total_profit,
    sb.ticket_cnt,
    AVG(wp.wp_image_count) AS avg_image_count,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_page_count
FROM sales_by_store sb
JOIN customer_address ca ON sb.ss_addr_sk = ca.ca_address_sk
JOIN store s ON sb.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales ON sb.ss_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_sales.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_sales.d_year = 2022
  AND s.s_state = ca.ca_state
  AND wp.wp_type = 'product'
GROUP BY
    ca.ca_city,
    ca.ca_state,
    d_sales.d_year,
    d_closed.d_current_month,
    s.s_store_name,
    s.s_market_desc,
    wp.wp_type,
    sb.total_sales,
    sb.total_profit,
    sb.ticket_cnt
HAVING sb.total_sales > 5000
ORDER BY sb.total_sales DESC
LIMIT 100
