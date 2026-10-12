/*
Goal: Compare high‑value catalog sales across two different filter sets, joining all selected TPC‑DS tables, applying multiple predicates, sampling the fact table, and ranking the results with a global ROW_NUMBER.
*/
WITH base1 AS (
    SELECT
        cs.cs_order_number AS order_number,
        cc.cc_name,
        s.s_store_name AS store_name,
        cs.cs_net_paid AS net_paid,
        cp.cp_description,
        cd.cd_gender,
        r.r_reason_desc,
        t.t_hour,
        cs.cs_ext_list_price
    FROM tpcds.catalog_sales cs
    TABLESAMPLE BERNOULLI (5)  -- sample 5 % of catalog_sales
    JOIN tpcds.time_dim t               ON cs.cs_sold_time_sk   = t.t_time_sk
    JOIN tpcds.store_returns sr         ON t.t_time_sk          = sr.sr_return_time_sk
    JOIN tpcds.store s                  ON sr.sr_store_sk       = s.s_store_sk
    JOIN tpcds.reason r                 ON sr.sr_reason_sk      = r.r_reason_sk
    JOIN tpcds.call_center cc           ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk   = cd.cd_demo_sk
    WHERE cs.cs_ext_list_price > 1500
      AND cd.cd_marital_status = 'M'
      AND cc.cc_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
      AND cc.cc_rec_start_date >= DATE '2001-01-01'
),
base2 AS (
    SELECT
        cs.cs_order_number AS order_number,
        cc.cc_name,
        s.s_store_name AS store_name,
        cs.cs_net_paid AS net_paid,
        cp.cp_description,
        cd.cd_gender,
        r.r_reason_desc,
        t.t_hour,
        cs.cs_ext_list_price
    FROM tpcds.catalog_sales cs
    TABLESAMPLE BERNOULLI (5)  -- sample 5 % of catalog_sales
    JOIN tpcds.time_dim t               ON cs.cs_sold_time_sk   = t.t_time_sk
    JOIN tpcds.store_returns sr         ON t.t_time_sk          = sr.sr_return_time_sk
    JOIN tpcds.store s                  ON sr.sr_store_sk       = s.s_store_sk
    JOIN tpcds.reason r                 ON sr.sr_reason_sk      = r.r_reason_sk
    JOIN tpcds.call_center cc           ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk   = cd.cd_demo_sk
    WHERE cs.cs_ext_list_price BETWEEN 500 AND 1000
      AND cd.cd_gender = 'F'
      AND s.s_state = 'CA'
      AND t.t_hour BETWEEN 12 AND 15
      AND s.s_rec_start_date >= DATE '2002-01-01'
)
SELECT
    u.order_number,
    u.cc_name,
    u.store_name,
    u.net_paid,
    ROW_NUMBER() OVER (ORDER BY u.net_paid DESC) AS row_num
FROM (
    SELECT * FROM base1
    UNION
    SELECT * FROM base2
) AS u
ORDER BY row_num
LIMIT 100
