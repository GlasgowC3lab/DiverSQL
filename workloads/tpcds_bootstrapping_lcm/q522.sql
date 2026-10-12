SELECT
    cc.cc_division_name,
    s.s_market_id,
    CASE 
        WHEN d_sales.d_month_seq % 2 = 0 THEN 'EvenMonth'
        ELSE 'OddMonth'
    END AS month_parity,
    wp.wp_type,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    COUNT(DISTINCT wp.wp_web_page_id) AS num_web_pages,
    SUM(ss.ss_ext_tax) AS total_tax,
    SUM(CASE WHEN d_wp_access.d_year = d_sales.d_year THEN 1 ELSE 0 END) AS same_year_access_cnt
FROM call_center cc
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
JOIN store_sales ss
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sales.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_sales.d_year = 2001
GROUP BY
    cc.cc_division_name,
    s.s_market_id,
    CASE 
        WHEN d_sales.d_month_seq % 2 = 0 THEN 'EvenMonth'
        ELSE 'OddMonth'
    END,
    wp.wp_type
ORDER BY total_sales DESC
LIMIT 100
