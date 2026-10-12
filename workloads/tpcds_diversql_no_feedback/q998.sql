WITH sales_data AS (
  SELECT
    cd.cd_gender AS gender,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    lp.page_cnt
  FROM catalog_sales cs
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN LATERAL (
    SELECT COUNT(*) AS page_cnt
    FROM catalog_page cp
    WHERE cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
  ) lp ON TRUE
  WHERE cc.cc_city = 'Hill'
    AND t.t_hour BETWEEN 8 AND 12
    AND EXISTS (
      SELECT 1 FROM warehouse w
      WHERE w.w_warehouse_sk = cs.cs_warehouse_sk
        AND w.w_city = 'New York'
    )
  GROUP BY cd.cd_gender, lp.page_cnt
),
returns_data AS (
  SELECT
    cd.cd_gender AS gender,
    SUM(cr.cr_return_amount) AS total_returns,
    lp.page_cnt
  FROM catalog_returns cr
  JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN LATERAL (
    SELECT COUNT(*) AS page_cnt
    FROM catalog_page cp
    WHERE cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
  ) lp ON TRUE
  WHERE cc.cc_city = 'Lakeview 10th'
    AND t.t_hour BETWEEN 13 AND 17
    AND EXISTS (
      SELECT 1 FROM warehouse w
      WHERE w.w_warehouse_sk = cr.cr_warehouse_sk
        AND w.w_city = 'New York'
    )
  GROUP BY cd.cd_gender, lp.page_cnt
)
SELECT gender,
       total_sales AS metric,
       page_cnt,
       'sales' AS source
FROM sales_data
UNION ALL
SELECT gender,
       total_returns AS metric,
       page_cnt,
       'returns' AS source
FROM returns_data
ORDER BY gender, metric DESC
LIMIT 100
