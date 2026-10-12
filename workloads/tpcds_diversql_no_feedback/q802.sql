WITH base AS (
  SELECT
    s.s_store_name,
    i.i_brand,
    d_ws_sold.d_year,
    sm.sm_type,
    we.web_name,
    cp.cp_department,
    SUM(ws.ws_net_paid) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    SUM(sr.sr_net_loss) AS total_return_loss
  FROM web_sales ws
  JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
  JOIN date_dim d_sr_return ON sr.sr_returned_date_sk = d_sr_return.d_date_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                    AND inv.inv_warehouse_sk = w.w_warehouse_sk
                    AND inv.inv_date_sk = d_ws_sold.d_date_sk
  JOIN call_center cc ON cc.cc_closed_date_sk = d_ws_sold.d_date_sk
  JOIN catalog_page cp ON cp.cp_end_date_sk = d_ws_sold.d_date_sk
  WHERE d_ws_sold.d_year = 2002
    AND s.s_state = 'TX'
    AND i.i_color = 'Red'
    AND sm.sm_type = 'AIR'
    AND we.web_country = 'United States'
    AND cc.cc_country = 'United States'
    AND cp.cp_department = 'Sports'
    AND r.r_reason_desc = 'Customer Not Satisfied'
  GROUP BY
    s.s_store_name,
    i.i_brand,
    d_ws_sold.d_year,
    sm.sm_type,
    we.web_name,
    cp.cp_department
)
SELECT
  b.s_store_name,
  b.i_brand,
  b.d_year,
  b.sm_type,
  b.web_name,
  b.cp_department,
  b.total_sales,
  b.order_cnt,
  b.avg_discount,
  b.total_return_loss,
  ROW_NUMBER() OVER (PARTITION BY b.s_store_name ORDER BY b.total_sales DESC) AS sales_rank,
  y.target_year
FROM base b
CROSS JOIN (VALUES (2020), (2021), (2022)) AS y(target_year)
ORDER BY b.total_sales DESC
LIMIT 100
