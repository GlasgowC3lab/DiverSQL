WITH
cs AS (
  SELECT cs.cs_order_number,
         cs.cs_item_sk,
         cs.cs_call_center_sk,
         cs.cs_catalog_page_sk,
         cs.cs_ship_mode_sk,
         cs.cs_bill_cdemo_sk,
         cs.cs_ship_cdemo_sk,
         cs.cs_ext_sales_price
  FROM catalog_sales cs
),
cr AS (
  SELECT cr.cr_order_number,
         cr.cr_item_sk,
         cr.cr_call_center_sk,
         cr.cr_catalog_page_sk,
         cr.cr_ship_mode_sk,
         cr.cr_refunded_cdemo_sk,
         cr.cr_returning_cdemo_sk,
         cr.cr_return_amount
  FROM catalog_returns cr
),
order_intersection AS (
  SELECT cs_order_number AS order_number FROM cs
  INTERSECT
  SELECT cr_order_number FROM cr
),
joined AS (
  SELECT
    i.i_item_id,
    i.i_brand,
    cd_bill.cd_gender AS bill_gender,
    cd_ship.cd_gender AS ship_gender,
    sm.sm_type,
    cc.cc_name,
    cp.cp_department,
    wp.wp_type,
    ws.ws_net_paid,
    sr.sr_return_amt,
    cr_sub.cr_return_amount,
    cs.cs_ext_sales_price,
    i.i_item_sk
  FROM cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  FULL OUTER JOIN store_returns sr
    ON i.i_item_sk = sr.sr_item_sk
  LEFT JOIN web_sales ws
    ON i.i_item_sk = ws.ws_item_sk
  LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN (
    SELECT cr.cr_item_sk, cr.cr_order_number, cr.cr_return_amount
    FROM cr
  ) cr_sub
    ON cr_sub.cr_item_sk = i.i_item_sk AND cr_sub.cr_order_number = cs.cs_order_number
  WHERE EXISTS (
    SELECT 1 FROM order_intersection oi WHERE oi.order_number = cs.cs_order_number
  )
),
lateral_agg AS (
  SELECT
    j.*, 
    ws_agg.total_qty
  FROM joined j
  LEFT JOIN LATERAL (
    SELECT SUM(ws_quantity) AS total_qty
    FROM web_sales ws2
    WHERE ws2.ws_item_sk = j.i_item_sk
  ) ws_agg ON TRUE
)
SELECT
  i_item_id,
  i_brand,
  bill_gender,
  ship_gender,
  sm_type,
  cc_name,
  cp_department,
  wp_type,
  SUM(cs_ext_sales_price) AS total_sales_price,
  SUM(cr_return_amount) AS total_return_amount,
  SUM(sr_return_amt) AS total_store_return,
  SUM(ws_net_paid) AS total_web_paid,
  SUM(total_qty) AS total_web_quantity
FROM lateral_agg
GROUP BY CUBE (i_item_id, i_brand, bill_gender, ship_gender, sm_type, cc_name, cp_department, wp_type)
ORDER BY total_sales_price DESC
LIMIT 100
