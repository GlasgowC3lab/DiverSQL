WITH filtered_returns AS (
    SELECT cr.*, d_ret.d_date
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret ON cr.cr_returned_time_sk = t_ret.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd_ret ON cr.cr_refunded_hdemo_sk = hd_ret.hd_demo_sk
    WHERE d_ret.d_year = 2001                         -- predicate 1
      AND t_ret.t_hour BETWEEN 8 AND 18               -- predicate 2
      AND cc.cc_state = 'CA'                         -- predicate 3
      AND cp.cp_type = 'Electronic'                  -- predicate 4
      AND w.w_state = 'TX'                           -- predicate 5
      AND hd_ret.hd_income_band_sk = 5               -- predicate 6
),
filtered_web AS (
    SELECT ws.*, d_ws.d_date
    FROM web_sales ws
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d_ws.d_year = 2001                         -- predicate 7
      AND t_ws.t_hour BETWEEN 9 AND 17               -- predicate 8
      AND wp.wp_autogen_flag = 'N'                  -- predicate 9
      AND site.web_market_manager = 'John Doe'      -- predicate 10
      AND w.w_city = 'Seattle'                      -- predicate 11
),
filtered_store AS (
    SELECT ss.*, d_ss.d_date
    FROM store_sales ss
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    WHERE d_ss.d_year = 2001                         -- predicate 12
      AND t_ss.t_hour BETWEEN 10 AND 20              -- predicate 13
      AND hd_ss.hd_vehicle_count >= 1               -- predicate 14
)
SELECT
    d_ret.d_date                             AS return_date,
    cc.cc_name                               AS call_center_name,
    cp.cp_department                         AS catalog_department,
    w.w_warehouse_name                       AS warehouse_name,
    site.web_name                            AS website_name,
    wp.wp_url                                AS page_url,
    COUNT(DISTINCT cr.cr_order_number)       AS distinct_return_orders,
    COUNT(DISTINCT ws.ws_order_number)       AS distinct_web_orders,
    COUNT(DISTINCT ss.ss_ticket_number)      AS distinct_store_tickets,
    SUM(ss.ss_net_paid)                      AS total_store_net_paid,
    AVG(ws.ws_net_paid)                      AS avg_web_net_paid,
    MIN(cc.cc_gmt_offset)                    AS min_cc_gmt_offset,
    MAX(w.w_gmt_offset)                      AS max_warehouse_gmt_offset,
    ROW_NUMBER() OVER (ORDER BY d_ret.d_date) AS rn
FROM filtered_returns cr
JOIN date_dim d_ret          ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN call_center cc          ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp         ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w             ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN household_demographics hd_ret ON cr.cr_refunded_hdemo_sk = hd_ret.hd_demo_sk
JOIN filtered_web ws        ON ws.ws_order_number = cr.cr_order_number
JOIN filtered_store ss      ON ss.ss_ticket_number = ws.ws_order_number
JOIN web_page wp            ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site site          ON ws.ws_web_site_sk = site.web_site_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_order_number = ws.ws_order_number
      AND cr2.cr_return_amount > 0
)
GROUP BY
    d_ret.d_date,
    cc.cc_name,
    cp.cp_department,
    w.w_warehouse_name,
    site.web_name,
    wp.wp_url
ORDER BY rn
LIMIT 100
