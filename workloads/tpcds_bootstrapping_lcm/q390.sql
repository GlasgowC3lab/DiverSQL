SELECT
    d_sold.d_date AS sold_date,
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_closed.d_date AS store_closed_date,
    d_closed.d_year AS closed_year,
    d_access.d_date AS page_access_date,
    wp.wp_url,
    wp.wp_type,
    SUM(ss.ss_ext_sales_price) AS total_ext_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    AVG(ss.ss_wholesale_cost) AS avg_wholesale_cost,
    SUM(ss.ss_quantity) AS total_quantity
FROM store_sales ss
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE ss.ss_quantity > 0
GROUP BY
    d_sold.d_date,
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_closed.d_date,
    d_closed.d_year,
    d_access.d_date,
    wp.wp_url,
    wp.wp_type
ORDER BY total_ext_sales DESC
LIMIT 100
