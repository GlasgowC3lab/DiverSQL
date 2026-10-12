SELECT
    d.d_year AS sold_year,
    d.d_quarter_name AS sold_quarter,
    s.s_state AS store_state,
    ws.web_name AS site_name,
    wp.wp_type AS page_type,
    CASE WHEN d.d_quarter_seq % 2 = 0 THEN 'EvenQuarter' ELSE 'OddQuarter' END AS quarter_parity,
    COUNT(*) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(cs.cs_quantity) AS avg_quantity,
    SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_net_profit ELSE 0 END) AS positive_profit,
    SUM(CASE WHEN ws.web_gmt_offset > 0 THEN cs.cs_ext_sales_price ELSE 0 END) AS sales_price_positive_gmt,
    MIN(d_ship.d_month_seq) AS ship_month_seq,
    MAX(d_web_close.d_year) AS web_close_year,
    MIN(d_wp_access.d_dow) AS page_access_day_of_week
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
JOIN date_dim d_web_close ON ws.web_close_date_sk = d_web_close.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND cs.cs_net_paid > 0
GROUP BY
    d.d_year,
    d.d_quarter_name,
    s.s_state,
    ws.web_name,
    wp.wp_type,
    CASE WHEN d.d_quarter_seq % 2 = 0 THEN 'EvenQuarter' ELSE 'OddQuarter' END
HAVING COUNT(*) > 5
ORDER BY total_net_paid DESC
LIMIT 100
