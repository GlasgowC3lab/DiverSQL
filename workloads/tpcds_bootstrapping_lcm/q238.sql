WITH store_sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_addr_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS ticket_count,
        AVG(ss.ss_quantity) AS avg_quantity
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_addr_sk, ss.ss_sold_date_sk
)
SELECT
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    d.d_year,
    d.d_month_seq,
    d.d_day_name,
    s.s_store_name,
    s.s_market_desc,
    s.s_manager,
    agg.total_sales,
    agg.total_profit,
    agg.ticket_count,
    agg.avg_quantity,
    wp.wp_url,
    wp.wp_type,
    wp.wp_char_count,
    wp.wp_image_count,
    wp.wp_link_count,
    d_create.d_day_name AS store_closed_day,
    d_access.d_day_name AS wp_access_day
FROM store_sales_agg agg
JOIN customer_address ca ON agg.ss_addr_sk = ca.ca_address_sk
JOIN store s ON agg.ss_store_sk = s.s_store_sk
JOIN date_dim d ON agg.ss_sold_date_sk = d.d_date_sk
JOIN date_dim d_create ON s.s_closed_date_sk = d_create.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_create.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d.d_year = 2021
  AND s.s_state = 'TX'
  AND wp.wp_type = 'article'
ORDER BY agg.total_sales DESC
LIMIT 50
