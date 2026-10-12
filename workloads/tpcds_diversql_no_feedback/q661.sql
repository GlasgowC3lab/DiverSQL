WITH
  inv_agg AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_warehouse_sk
  ),
  ss_agg AS (
    SELECT ss_ticket_number,
           ss_store_sk,
           ss_sold_time_sk,
           SUM(ss_net_paid) AS net_paid,
           COUNT(*) AS line_cnt
    FROM store_sales
    WHERE ss_quantity > 1
    GROUP BY ss_ticket_number, ss_store_sk, ss_sold_time_sk
  )
SELECT
  cc.cc_name,
  w.w_warehouse_name,
  cp.cp_department,
  p.p_promo_name,
  ca.ca_city,
  cd.cd_gender,
  td.t_hour,
  td.t_meal_time,
  inv_agg.total_qty_on_hand,
  SUM(cs.cs_ext_sales_price)               AS catalog_sales_total,
  SUM(ss_agg.net_paid)                     AS store_sales_total,
  SUM(ws.ws_sales_price)                   AS web_sales_total,
  SUM(cr.cr_return_amount)                AS catalog_return_total,
  SUM(sr.sr_return_amt)                   AS store_return_total,
  SUM(wr.wr_return_amt)                   AS web_return_total
FROM catalog_sales cs
JOIN time_dim td                     ON cs.cs_sold_time_sk = td.t_time_sk
JOIN call_center cc                  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp                 ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p                     ON cs.cs_promo_sk = p.p_promo_sk
JOIN warehouse w                     ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer c                      ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca             ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN catalog_returns cr        ON cr.cr_order_number = cs.cs_order_number
JOIN inv_agg                         ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
JOIN ss_agg                         ON ss_agg.ss_sold_time_sk = td.t_time_sk
JOIN store_returns sr               ON sr.sr_ticket_number = ss_agg.ss_ticket_number
JOIN web_sales ws                   ON ws.ws_sold_time_sk = td.t_time_sk
JOIN web_site wsit                   ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN web_returns wr                 ON wr.wr_order_number = ws.ws_order_number
WHERE cc.cc_name = 'Mid Atlantic_2'
  AND w.w_gmt_offset = -5.00
  AND p.p_discount_active = 'Y'
  AND ca.ca_state = 'CA'
  AND cd.cd_gender = 'M'
GROUP BY
  cc.cc_name,
  w.w_warehouse_name,
  cp.cp_department,
  p.p_promo_name,
  ca.ca_city,
  cd.cd_gender,
  td.t_hour,
  td.t_meal_time,
  inv_agg.total_qty_on_hand
HAVING SUM(cs.cs_ext_sales_price) > 0
UNION
SELECT
  cc.cc_name,
  w.w_warehouse_name,
  cp.cp_department,
  p.p_promo_name,
  ca.ca_city,
  cd.cd_gender,
  td.t_hour,
  td.t_meal_time,
  inv_agg.total_qty_on_hand,
  SUM(cs.cs_ext_sales_price)               AS catalog_sales_total,
  SUM(ss_agg.net_paid)                     AS store_sales_total,
  SUM(ws.ws_sales_price)                   AS web_sales_total,
  SUM(cr.cr_return_amount)                AS catalog_return_total,
  SUM(sr.sr_return_amt)                   AS store_return_total,
  SUM(wr.wr_return_amt)                   AS web_return_total
FROM catalog_sales cs
JOIN time_dim td                     ON cs.cs_sold_time_sk = td.t_time_sk
JOIN call_center cc                  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp                 ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p                     ON cs.cs_promo_sk = p.p_promo_sk
JOIN warehouse w                     ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer c                      ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca             ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN catalog_returns cr        ON cr.cr_order_number = cs.cs_order_number
JOIN inv_agg                         ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
JOIN ss_agg                         ON ss_agg.ss_sold_time_sk = td.t_time_sk
JOIN store_returns sr               ON sr.sr_ticket_number = ss_agg.ss_ticket_number
JOIN web_sales ws                   ON ws.ws_sold_time_sk = td.t_time_sk
JOIN web_site wsit                   ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN web_returns wr                 ON wr.wr_order_number = ws.ws_order_number
WHERE cc.cc_name = 'North Midwest'
  AND w.w_gmt_offset = -5.00
  AND p.p_discount_active = 'Y'
  AND ca.ca_state = 'CA'
  AND cd.cd_gender = 'M'
GROUP BY
  cc.cc_name,
  w.w_warehouse_name,
  cp.cp_department,
  p.p_promo_name,
  ca.ca_city,
  cd.cd_gender,
  td.t_hour,
  td.t_meal_time,
  inv_agg.total_qty_on_hand
HAVING SUM(cs.cs_ext_sales_price) > 0
ORDER BY catalog_sales_total DESC
LIMIT 100
