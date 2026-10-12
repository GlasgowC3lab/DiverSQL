WITH sampled_sales AS (
  SELECT *
  FROM web_sales
  TABLESAMPLE BERNOULLI (10)
),
reason_filtered AS (
  SELECT r_reason_sk, r_reason_desc
  FROM reason
  WHERE r_reason_desc LIKE '%defect%'
),
intersect_keys AS (
  SELECT cr_returned_date_sk AS date_sk FROM catalog_returns
  INTERSECT
  SELECT sr_returned_date_sk FROM store_returns
)
SELECT
  ws.ws_order_number,
  d.d_year,
  c.c_customer_id,
  ca.ca_state,
  CASE 
    WHEN cd.cd_credit_rating = 'Good' THEN 'Preferred'
    WHEN cd.cd_credit_rating = 'Low Risk' THEN 'Standard'
    ELSE 'Other'
  END AS customer_segment,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank,
  COUNT(DISTINCT wr.wr_return_quantity) AS web_return_count,
  COUNT(DISTINCT sr.sr_return_quantity) AS store_return_count,
  COUNT(DISTINCT cr.cr_return_quantity) AS catalog_return_count,
  r.r_reason_desc
FROM sampled_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
  AND wr.wr_item_sk = ws.ws_item_sk
LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = ws.ws_sold_date_sk
LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = ws.ws_sold_date_sk
LEFT JOIN reason_filtered r ON r.r_reason_sk = COALESCE(wr.wr_reason_sk, sr.sr_reason_sk, cr.cr_reason_sk)
WHERE d.d_year = 2001
  AND ca.ca_state IN ('TX', 'CA', 'NY')
  AND t.t_hour BETWEEN 9 AND 17
  AND sm.sm_type = 'AIR'
  AND EXISTS (SELECT 1 FROM intersect_keys ik WHERE ik.date_sk = ws.ws_sold_date_sk)
  AND cd.cd_dep_count >= 2
GROUP BY
  ws.ws_order_number,
  d.d_year,
  c.c_customer_id,
  ca.ca_state,
  cd.cd_credit_rating,
  r.r_reason_desc
ORDER BY sales_rank
LIMIT 100
