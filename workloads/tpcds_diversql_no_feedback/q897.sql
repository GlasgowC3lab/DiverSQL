WITH union_sales AS (
  -- Catalog sales side
  SELECT
    d.d_date,
    w.w_warehouse_name,
    SUM(cs.cs_net_paid) AS sales_amount
  FROM catalog_sales cs
  JOIN date_dim d               ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN time_dim t               ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN warehouse w              ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN call_center cc           ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm             ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_demographics cdb ON cs.cs_bill_cdemo_sk = cdb.cd_demo_sk
  JOIN household_demographics hdb ON cs.cs_bill_hdemo_sk = hdb.hd_demo_sk
  JOIN inventory i              ON i.inv_warehouse_sk = w.w_warehouse_sk
                                 AND i.inv_date_sk = d.d_date_sk
  LEFT JOIN catalog_returns cr  ON cr.cr_order_number = cs.cs_order_number
                                 AND cr.cr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 1999
    AND cs.cs_quantity > 5
    AND w.w_state = 'CA'
    AND cc.cc_state = 'CA'
    AND i.inv_quantity_on_hand > 500
    AND sm.sm_type = 'AIR'
  GROUP BY d.d_date, w.w_warehouse_name

  UNION

  -- Web sales side
  SELECT
    d.d_date,
    w.w_warehouse_name,
    SUM(ws.ws_net_paid) AS sales_amount
  FROM web_sales ws
  JOIN date_dim d               ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN time_dim t               ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN warehouse w              ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_page wp              ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site we              ON ws.ws_web_site_sk = we.web_site_sk
  JOIN ship_mode sm             ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_demographics cdb ON ws.ws_bill_cdemo_sk = cdb.cd_demo_sk
  JOIN household_demographics hdb ON ws.ws_bill_hdemo_sk = hdb.hd_demo_sk
  JOIN inventory i              ON i.inv_warehouse_sk = w.w_warehouse_sk
                                 AND i.inv_date_sk = d.d_date_sk
  LEFT JOIN store_returns sr    ON sr.sr_returned_date_sk = d.d_date_sk
                                 AND sr.sr_return_time_sk = t.t_time_sk
  WHERE d.d_year = 1999
    AND ws.ws_quantity > 5
    AND w.w_state = 'CA'
    AND we.web_state = 'CA'
    AND i.inv_quantity_on_hand > 500
    AND sm.sm_type = 'AIR'
    AND sr.sr_return_quantity > 0
  GROUP BY d.d_date, w.w_warehouse_name
)
SELECT
  d_date,
  w_warehouse_name,
  sales_amount,
  RANK() OVER (PARTITION BY w_warehouse_name ORDER BY sales_amount DESC) AS sales_rank
FROM union_sales
ORDER BY sales_amount DESC
LIMIT 100
