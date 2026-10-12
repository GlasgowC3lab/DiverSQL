WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r ON r.r_reason_sk = cr.cr_reason_sk
    LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND sm.sm_type = 'AIR'
      AND wsite.web_country = 'United States'
      AND c.c_birth_country = 'URUGUAY'
      AND cc.cc_class = 'large'
    GROUP BY ws.ws_web_site_sk, ws.ws_ship_mode_sk, ws.ws_sold_date_sk
)
SELECT
    wsite.web_name,
    sm.sm_type,
    AVG(sales_agg.total_net_paid) AS avg_daily_net_paid,
    SUM(sales_agg.order_cnt) AS total_orders
FROM sales_agg
JOIN web_site wsite ON sales_agg.ws_web_site_sk = wsite.web_site_sk
JOIN ship_mode sm ON sales_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d2 ON sales_agg.ws_sold_date_sk = d2.d_date_sk
WHERE d2.d_month_seq BETWEEN 1200 AND 1210
GROUP BY wsite.web_name, sm.sm_type
HAVING AVG(sales_agg.total_net_paid) > 10000
ORDER BY avg_daily_net_paid DESC
LIMIT 100
