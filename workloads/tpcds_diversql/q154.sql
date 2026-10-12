WITH ss_time AS (
   SELECT
       ss.ss_sold_date_sk,
       ss.ss_sold_time_sk,
       ss.ss_item_sk,
       ss.ss_customer_sk,
       ss.ss_cdemo_sk,
       ss.ss_addr_sk,
       ss.ss_store_sk,
       ss.ss_net_paid,
       ss.ss_ext_sales_price,
       td.t_time_sk,
       td.t_hour,
       td.t_minute,
       td.t_am_pm
   FROM store_sales ss
   FULL OUTER JOIN time_dim td
       ON ss.ss_sold_time_sk = td.t_time_sk
),
joined AS (
   SELECT
       s.s_store_name               AS store_name,
       s.s_state                    AS store_state,
       w.w_warehouse_name           AS warehouse_name,
       w.w_gmt_offset               AS warehouse_gmt_offset,
       r.r_reason_desc              AS reason_desc,
       ws.ws_order_number           AS order_number,
       ws.ws_net_paid               AS ws_net_paid,
       ws.ws_coupon_amt             AS ws_coupon_amt,
       ws.ws_ext_sales_price        AS ws_ext_sales_price,
       ss_time.ss_net_paid          AS ss_net_paid,
       ss_time.ss_ext_sales_price   AS ss_ext_sales_price,
       cd.cd_gender                 AS gender,
       c.c_birth_year               AS birth_year,
       td.t_hour                    AS hour_of_day,
       we.web_country               AS web_country,
       wp.wp_web_page_sk            AS web_page_sk
   FROM ss_time
   LEFT JOIN store s
       ON ss_time.ss_store_sk = s.s_store_sk
   LEFT JOIN web_sales ws
       ON ss_time.t_time_sk = ws.ws_sold_time_sk
   LEFT JOIN warehouse w
       ON ws.ws_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN web_returns wr
       ON ws.ws_order_number = wr.wr_order_number
   LEFT JOIN reason r
       ON wr.wr_reason_sk = r.r_reason_sk
   LEFT JOIN web_page wp
       ON ws.ws_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN web_site we
       ON ws.ws_web_site_sk = we.web_site_sk
   LEFT JOIN customer c
       ON ws.ws_bill_customer_sk = c.c_customer_sk
   LEFT JOIN customer_address ca
       ON ws.ws_bill_addr_sk = ca.ca_address_sk
   LEFT JOIN customer_demographics cd
       ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN time_dim td
       ON ws.ws_sold_time_sk = td.t_time_sk
   WHERE
       s.s_state = 'CA'
       AND we.web_country = 'United States'
       AND cd.cd_gender = 'M'
       AND c.c_birth_year = 1985
       AND r.r_reason_desc = 'Customer not satisfied'
       AND w.w_gmt_offset = -5.00
       AND td.t_hour BETWEEN 9 AND 17
       AND ws.ws_warehouse_sk IN (SELECT w_warehouse_sk FROM warehouse WHERE w_country = 'United States')
)
SELECT
    store_name,
    warehouse_name,
    reason_desc,
    COUNT(DISTINCT order_number)                         AS order_cnt,
    SUM(COALESCE(ss_net_paid, 0) + COALESCE(ws_net_paid, 0)) AS total_net_paid,
    AVG(ws_coupon_amt)                                   AS avg_coupon_amt,
    MIN(ws_ext_sales_price)                              AS min_ext_sales_price,
    MAX(ws_ext_sales_price)                              AS max_ext_sales_price,
    ROW_NUMBER() OVER (ORDER BY SUM(COALESCE(ss_net_paid, 0) + COALESCE(ws_net_paid, 0)) DESC) AS sales_rank
FROM joined
GROUP BY
    store_name,
    warehouse_name,
    reason_desc
ORDER BY total_net_paid DESC
LIMIT 100
