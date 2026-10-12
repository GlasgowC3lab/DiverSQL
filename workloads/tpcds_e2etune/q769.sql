WITH call_center_dates AS (
  SELECT cc.cc_call_center_sk,
         cc.cc_state,
         cc.cc_class,
         cc.cc_employees,
         cc.cc_sq_ft,
         cc.cc_call_center_id,
         cc.cc_open_date_sk,
         cc.cc_closed_date_sk,
         od.d_year AS open_year,
         cd.d_year AS closed_year
  FROM call_center cc
  JOIN date_dim od ON cc.cc_open_date_sk = od.d_date_sk
  JOIN date_dim cd ON cc.cc_closed_date_sk = cd.d_date_sk
  WHERE cc.cc_class IN ('large', 'medium')
    AND cc.cc_employees > 2000000
),
customer_aggregates AS (
  SELECT ccd.cc_state,
         ccd.cc_class,
         COUNT(DISTINCT c.c_customer_sk) AS total_customers,
         AVG(date_diff('day', fs.d_date, lr.d_date)) AS avg_days_to_last_review
  FROM call_center_dates ccd
  JOIN customer c
    ON c.c_first_sales_date_sk >= ccd.cc_open_date_sk
   AND c.c_first_sales_date_sk <= ccd.cc_closed_date_sk
  JOIN date_dim fs ON c.c_first_sales_date_sk = fs.d_date_sk
  JOIN date_dim lr ON c.c_last_review_date = lr.d_date_sk
  GROUP BY ccd.cc_state, ccd.cc_class
),
catalog_page_aggregates AS (
  SELECT ccd.cc_state,
         ccd.cc_class,
         COUNT(DISTINCT cp.cp_catalog_page_id) AS total_catalog_pages
  FROM call_center_dates ccd
  JOIN catalog_page cp
    ON cp.cp_start_date_sk >= ccd.cc_open_date_sk
   AND cp.cp_end_date_sk <= ccd.cc_closed_date_sk
  GROUP BY ccd.cc_state, ccd.cc_class
),
call_center_metrics AS (
  SELECT cc.cc_state,
         cc.cc_class,
         AVG(cc.cc_employees) AS avg_employees,
         SUM(cc.cc_sq_ft) AS total_sq_ft
  FROM call_center_dates cc
  GROUP BY cc.cc_state, cc.cc_class
)
SELECT cm.cc_state,
       cm.cc_class,
       cm.avg_employees,
       cm.total_sq_ft,
       ca.total_customers,
       ca.avg_days_to_last_review,
       cp.total_catalog_pages
FROM call_center_metrics cm
JOIN customer_aggregates ca
  ON cm.cc_state = ca.cc_state AND cm.cc_class = ca.cc_class
JOIN catalog_page_aggregates cp
  ON cm.cc_state = cp.cc_state AND cm.cc_class = cp.cc_class
ORDER BY ca.total_customers DESC
LIMIT 100
