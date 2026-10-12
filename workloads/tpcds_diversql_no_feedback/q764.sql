WITH joined AS (
  SELECT
    s.s_store_name,
    s.s_state,
    ss.ss_quantity,
    ss.ss_net_paid,
    cd_ss.cd_gender,
    cd_ss.cd_education_status,
    cs.cs_quantity,
    cs.cs_net_paid,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    ws.ws_quantity,
    ws.ws_net_paid,
    sm_cs.sm_type AS cs_ship_type,
    CASE
      WHEN cs.cs_net_paid > 1000 THEN 'High'
      WHEN cs.cs_net_paid > 500 THEN 'Medium'
      ELSE 'Low'
    END AS cs_payment_category
  FROM store_sales ss
  RIGHT OUTER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN customer_demographics cd_ss
    ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
  LEFT JOIN catalog_sales cs
    ON cs.cs_bill_cdemo_sk = cd_ss.cd_demo_sk
  LEFT JOIN ship_mode sm_cs
    ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
  LEFT JOIN ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
  LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  LEFT JOIN web_sales ws
    ON ws.ws_bill_cdemo_sk = cd_ss.cd_demo_sk
  LEFT JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
)
SELECT
  s_store_name,
  s_state,
  cd_gender,
  cd_education_status,
  cs_ship_type,
  cs_payment_category,
  COUNT(*) AS txn_count,
  SUM(ss_quantity) AS total_store_qty,
  SUM(cs_quantity) AS total_catalog_qty,
  SUM(ws_quantity) AS total_web_qty,
  SUM(cs_net_paid) AS total_catalog_net_paid,
  AVG(cs_net_paid) AS avg_catalog_net_paid,
  MIN(cr_return_amount) AS min_return_amount,
  MAX(cr_return_amount) AS max_return_amount
FROM joined
WHERE
  s_state = 'CA'
  AND cs_ship_type IN ('REGULAR', 'EXPRESS')
  AND cd_gender = 'M'
  AND cd_education_status = '4 yr Degree'
  AND cs_net_paid > 500
  AND cr_return_amount > 0
GROUP BY
  s_store_name,
  s_state,
  cd_gender,
  cd_education_status,
  cs_ship_type,
  cs_payment_category
ORDER BY
  total_catalog_net_paid DESC
LIMIT 100
