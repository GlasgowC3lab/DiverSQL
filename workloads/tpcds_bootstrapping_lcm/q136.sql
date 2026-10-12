SELECT
    cc.cc_name AS call_center_name,
    cc.cc_city AS call_center_city,
    s.s_store_name AS store_name,
    s.s_city AS store_city,
    w.web_name AS website_name,
    w.web_city AS website_city,
    d_sold.d_year AS sold_year,
    d_sold.d_quarter_name AS sold_quarter,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    MIN(date_diff('day', d_cc_open.d_date, d_cc_closed.d_date)) AS call_center_lifespan_days,
    MIN(date_diff('day', d_web_open.d_date, d_web_close.d_date)) AS website_lifespan_days,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_ship_delay_days,
    SUM(cs.cs_ext_sales_price) AS total_ext_sales_price,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
    SUM(cs.cs_coupon_amt) AS total_coupon_amount,
    SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_ext_sales_price), 0) AS profit_margin,
    SUM(cs.cs_ext_discount_amt) / NULLIF(SUM(cs.cs_ext_sales_price), 0) AS discount_rate
FROM catalog_sales cs
INNER JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
INNER JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
INNER JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
CROSS JOIN store s
INNER JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
CROSS JOIN web_site w
INNER JOIN date_dim d_web_open
    ON w.web_open_date_sk = d_web_open.d_date_sk
INNER JOIN date_dim d_web_close
    ON w.web_close_date_sk = d_web_close.d_date_sk
INNER JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
INNER JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
GROUP BY
    cc.cc_name,
    cc.cc_city,
    s.s_store_name,
    s.s_city,
    w.web_name,
    w.web_city,
    d_sold.d_year,
    d_sold.d_quarter_name
ORDER BY total_net_paid DESC
LIMIT 100
