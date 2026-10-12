SELECT
    cp.cp_department,
    d_sold.d_year AS sale_year,
    s.s_state AS store_state,
    ws.web_state AS website_state,
    CASE
        WHEN date_diff('day', d_sold.d_date, d_ship.d_date) > 7 THEN 'Long Delay'
        ELSE 'Short Delay'
    END AS shipping_delay,
    COUNT(*) AS order_count,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_ship_days
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_page_start
    ON cp.cp_start_date_sk = d_page_start.d_date_sk
JOIN date_dim d_page_end
    ON cp.cp_end_date_sk = d_page_end.d_date_sk
JOIN date_dim d_web_close
    ON ws.web_close_date_sk = d_web_close.d_date_sk
GROUP BY
    cp.cp_department,
    d_sold.d_year,
    s.s_state,
    ws.web_state,
    CASE
        WHEN date_diff('day', d_sold.d_date, d_ship.d_date) > 7 THEN 'Long Delay'
        ELSE 'Short Delay'
    END
ORDER BY total_net_paid DESC
LIMIT 100
