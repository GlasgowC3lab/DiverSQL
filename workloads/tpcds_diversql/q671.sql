/*
Goal: Analyze combined store and web sales performance for the year 2001, focusing on customer state, store, and shipping mode, while restricting to customers born in 1975 who also placed web orders with a list price > 150. The result is aggregated by several grouping sets and limited to the top 100 rows.
*/
WITH all_data AS (
    SELECT
        ss.ss_ext_sales_price,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ca.ca_state,
        d1.d_year,
        s.s_store_name,
        sm.sm_type,
        c.c_customer_sk
    FROM store_sales ss
    JOIN date_dim d1
      ON ss.ss_sold_date_sk = d1.d_date_sk
    JOIN time_dim t1
      ON ss.ss_sold_time_sk = t1.t_time_sk
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN web_sales ws
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d2
      ON ws.ws_sold_date_sk = d2.d_date_sk
    JOIN time_dim t2
      ON ws.ws_sold_time_sk = t2.t_time_sk
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site web
      ON ws.ws_web_site_sk = web.web_site_sk
    WHERE d1.d_year = 2001
      AND t1.t_am_pm = 'PM'
      AND web.web_mkt_class = 'New'
      AND ib.ib_lower_bound >= 50000
)
SELECT
    ca_state,
    d_year,
    s_store_name,
    sm_type,
    SUM(ss_ext_sales_price)      AS store_sales_total,
    SUM(ws_ext_sales_price)      AS web_sales_total,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    AVG(ss_quantity)             AS avg_store_qty,
    MAX(ws_net_profit)           AS max_web_profit
FROM all_data
WHERE EXISTS (
    SELECT 1
    FROM (
        SELECT c_customer_sk FROM customer WHERE c_birth_year = 1975
        INTERSECT
        SELECT ws_bill_customer_sk FROM web_sales WHERE ws_list_price > 150
    ) AS intersect_set
    WHERE intersect_set.c_customer_sk = all_data.c_customer_sk
)
GROUP BY GROUPING SETS (
    (ca_state, d_year),
    (s_store_name, d_year),
    (sm_type, d_year),
    ()
)
ORDER BY store_sales_total DESC
LIMIT 100
