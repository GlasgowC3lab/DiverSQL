WITH high_profit_sales AS (
   SELECT cs.cs_catalog_page_sk
   FROM tpcds.catalog_sales cs
   WHERE cs.cs_net_profit > 1000
   GROUP BY cs.cs_catalog_page_sk
),
dept_pages AS (
   SELECT cp.cp_catalog_page_sk
   FROM tpcds.catalog_page cp
   WHERE cp.cp_department = 'Electronics'
)
SELECT
   d_sold.d_year,
   cp.cp_department,
   w.w_warehouse_name,
   SUM(cs.cs_ext_sales_price) AS total_sales,
   COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
   MAX(cs.cs_net_profit) AS max_profit,
   lt.same_day_ship_cnt
FROM tpcds.catalog_sales cs
JOIN tpcds.date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN tpcds.time_dim t
  ON cs.cs_sold_time_sk = t.t_time_sk
JOIN tpcds.date_dim d_ship
  ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN tpcds.customer c_bill
  ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN tpcds.customer c_ship
  ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN tpcds.call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.date_dim d_cc_open
  ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN tpcds.date_dim d_cc_closed
  ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
CROSS JOIN LATERAL (
   SELECT COUNT(*) AS same_day_ship_cnt
   FROM tpcds.catalog_sales cs2
   WHERE cs2.cs_ship_date_sk = d_ship.d_date_sk
) lt
WHERE cs.cs_catalog_page_sk IN (
        SELECT cs_catalog_page_sk FROM high_profit_sales
        INTERSECT
        SELECT cp_catalog_page_sk FROM dept_pages
      )
  AND w.w_country = 'United States'
  AND d_sold.d_year BETWEEN 2000 AND 2002
  AND EXISTS (
        SELECT 1
        FROM tpcds.warehouse w2
        WHERE w2.w_warehouse_sk = cs.cs_warehouse_sk
          AND w2.w_suite_number NOT IN (
                SELECT suite
                FROM (
                      SELECT w3.w_suite_number AS suite
                      FROM tpcds.warehouse w3
                      WHERE w3.w_country = 'Canada'
                      EXCEPT
                      SELECT w4.w_suite_number
                      FROM tpcds.warehouse w4
                      WHERE w4.w_city = 'Seattle'
                ) sub_ex
          )
      )
GROUP BY d_sold.d_year, cp.cp_department, w.w_warehouse_name, lt.same_day_ship_cnt
ORDER BY total_sales DESC
LIMIT 100
