WITH ws_sampled AS (
   SELECT *
   FROM web_sales TABLESAMPLE BERNOULLI (10)
),
ws_data AS (
   SELECT
       ws.ws_order_number AS order_id,
       ws.ws_sold_date_sk AS event_date_sk,
       ws.ws_bill_customer_sk AS customer_sk,
       ws.ws_ext_sales_price AS amount,
       ws.ws_net_profit AS profit_loss,
       c.c_first_name,
       c.c_last_name,
       sm.sm_code AS ship_mode_code,
       w.w_warehouse_name,
       CAST(NULL AS varchar) AS reason_desc,
       d.d_year AS year,
       d.d_month_seq AS month_seq,
       'web' AS source_flag
   FROM ws_sampled ws
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
sr_data AS (
   SELECT
       sr.sr_ticket_number AS order_id,
       sr.sr_returned_date_sk AS event_date_sk,
       sr.sr_customer_sk AS customer_sk,
       sr.sr_return_amt AS amount,
       sr.sr_net_loss AS profit_loss,
       c.c_first_name,
       c.c_last_name,
       CAST(NULL AS varchar) AS ship_mode_code,
       CAST(NULL AS varchar) AS w_warehouse_name,
       r.r_reason_desc AS reason_desc,
       d.d_year AS year,
       d.d_month_seq AS month_seq,
       'return' AS source_flag
   FROM store_returns sr
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
),
unioned AS (
   SELECT * FROM ws_data
   UNION
   SELECT * FROM sr_data
),
date_joined AS (
   SELECT u.*,
          d.d_month_seq,
          d.d_year
   FROM unioned u
   JOIN date_dim d ON u.event_date_sk = d.d_date_sk
),
cc_cp_full AS (
   SELECT
       cc.cc_call_center_id,
       cc.cc_state,
       cc.cc_gmt_offset,
       cp.cp_catalog_page_id,
       cp.cp_type,
       d.d_date_sk
   FROM call_center cc
   FULL OUTER JOIN catalog_page cp
       ON cc.cc_open_date_sk = cp.cp_start_date_sk
   JOIN date_dim d
       ON d.d_date_sk = COALESCE(cc.cc_open_date_sk, cp.cp_start_date_sk)
)
SELECT
    dj.year,
    dj.month_seq,
    CASE WHEN dj.source_flag = 'web' THEN 'Online' ELSE 'Return' END AS transaction_type,
    dj.ship_mode_code,
    dj.w_warehouse_name,
    dj.reason_desc,
    SUM(dj.amount) AS total_amount,
    AVG(dj.profit_loss) AS avg_profit_loss,
    COUNT(DISTINCT dj.order_id) AS orders_cnt,
    MIN(dj.amount) AS min_amount,
    MAX(dj.amount) AS max_amount
FROM date_joined dj
LEFT JOIN cc_cp_full cc ON dj.event_date_sk = cc.d_date_sk
WHERE
    dj.year = 2001
    AND dj.ship_mode_code IN ('AIR', 'SEA')
    AND dj.w_warehouse_name IS NOT NULL
    AND dj.customer_sk IN (SELECT c_customer_sk FROM customer WHERE c_birth_year = 1965)
GROUP BY
    dj.year,
    dj.month_seq,
    dj.source_flag,
    dj.ship_mode_code,
    dj.w_warehouse_name,
    dj.reason_desc
ORDER BY
    dj.year DESC,
    dj.month_seq ASC,
    total_amount DESC
OFFSET 0
LIMIT 100
