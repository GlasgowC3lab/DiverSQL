WITH sales_no_return AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_warehouse_sk,
    cs.cs_net_paid,
    cs.cs_net_profit,
    c.c_customer_id,
    w.w_warehouse_id,
    cc.cc_name,
    sum(cs.cs_net_paid) OVER (
        PARTITION BY cs.cs_warehouse_sk
        ORDER BY cs.cs_sold_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_warehouse_paid
  FROM tpcds.catalog_sales cs
  JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE cs.cs_order_number NOT IN (
    SELECT cr.cr_order_number FROM tpcds.catalog_returns cr
  )
)
SELECT
  w_warehouse_id,
  cc_name,
  COUNT(*) AS orders_cnt,
  SUM(cs_net_paid) AS total_paid,
  SUM(cs_net_profit) AS total_profit,
  MAX(running_warehouse_paid) AS final_running_paid,
  CASE WHEN regexp_like(cc_name, '^.*Center$') THEN 'EndsWithCenter' ELSE 'Other' END AS cc_name_type,
  substr(w_warehouse_id, 1, 5) AS warehouse_prefix,
  concat(w_warehouse_id, '-', cc_name) AS warehouse_cc_concat,
  regexp_extract(w_warehouse_id, '(\\d+)$', 1) AS warehouse_id_num
FROM sales_no_return
WHERE w_warehouse_id LIKE 'AAAAAAA%'
GROUP BY w_warehouse_id, cc_name
HAVING COUNT(*) > 5
ORDER BY total_paid DESC
LIMIT 100
