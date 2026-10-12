WITH
    sampled_store_sales AS (
        SELECT *
        FROM store_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    intersect_customers AS (
        SELECT c.c_customer_id
        FROM customer c
        WHERE c.c_preferred_cust_flag = 'Y'
        INTERSECT
        SELECT CAST(ws.ws_bill_customer_sk AS VARCHAR) AS c_customer_id
        FROM web_sales ws
        WHERE ws.ws_quantity > 0
    ),
    aggregated AS (
        SELECT
            d.d_year,
            sm1.sm_type,
            SUM(ss.ss_quantity) AS total_quantity,
            COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
            SUM(ss.ss_net_paid) AS total_net_paid,
            SUM(ss.ss_net_profit) AS total_net_profit,
            COUNT(DISTINCT ic.c_customer_id) AS intersect_customer_count
        FROM sampled_store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        LEFT JOIN store_returns sr
            ON ss.ss_ticket_number = sr.sr_ticket_number
            AND ss.ss_item_sk = sr.sr_item_sk
        LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
        LEFT JOIN catalog_returns cr ON ss.ss_ticket_number = cr.cr_order_number
        FULL OUTER JOIN web_returns wr ON cr.cr_order_number = wr.wr_order_number
        LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
        LEFT JOIN ship_mode sm1 ON cr.cr_ship_mode_sk = sm1.sm_ship_mode_sk
        LEFT JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
        LEFT JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
        LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
        LEFT JOIN intersect_customers ic ON c.c_customer_id = ic.c_customer_id
        CROSS JOIN LATERAL (
            SELECT CASE WHEN ss.ss_quantity > 5 THEN 'High' ELSE 'Low' END AS qty_level
        ) q
        WHERE d.d_year = 2001
        GROUP BY d.d_year, sm1.sm_type
    )
SELECT
    d_year,
    sm_type,
    CASE WHEN total_quantity > 100 THEN 'Large' ELSE 'Small' END AS size_category,
    distinct_customers,
    total_net_paid,
    total_net_profit,
    intersect_customer_count
FROM aggregated
ORDER BY total_net_paid DESC
LIMIT 100
