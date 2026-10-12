WITH max_price_cte AS (
    SELECT MAX(i_current_price) AS max_price FROM item
)
SELECT
    ws.web_site_id,
    ws.web_name,
    d_ws.d_year,
    cc.cc_name,
    p.p_promo_name,
    i.i_item_id,
    i.i_product_name,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(cr.cr_return_amount) AS total_catalog_returns,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_transactions,
    MAX(i.i_current_price) AS max_item_price,
    (SELECT max_price FROM max_price_cte) AS overall_max_price
FROM store_sales ss
JOIN date_dim d_sold
  ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
  ON ss.ss_sold_time_sk = t_sold.t_time_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
  AND sr.sr_item_sk = ss.ss_item_sk
LEFT JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_sales cs
  ON cs.cs_item_sk = i.i_item_sk
  AND cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr
  ON cr.cr_item_sk = i.i_item_sk
  AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_cr
  ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN time_dim t_cr
  ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
  AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_ws
  ON inv.inv_date_sk = d_ws.d_date_sk
RIGHT OUTER JOIN web_site ws
  ON ws.web_open_date_sk = d_ws.d_date_sk
WHERE i.i_current_price > (SELECT max_price FROM max_price_cte) / 2
GROUP BY
    ws.web_site_id,
    ws.web_name,
    d_ws.d_year,
    cc.cc_name,
    p.p_promo_name,
    i.i_item_id,
    i.i_product_name,
    (SELECT max_price FROM max_price_cte)
ORDER BY total_store_sales DESC
LIMIT 100
