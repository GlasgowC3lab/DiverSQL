/*
  Goal: Summarize web sales, catalog returns and inventory by web site, year, warehouse, ship mode and return reason, applying several realistic filters and retaining all web sites via a RIGHT OUTER JOIN.
*/
SELECT
  wsite.web_site_id,
  d_sold.d_year,
  w_warehouse.w_warehouse_name,
  sm.sm_type,
  r.r_reason_desc,
  SUM(ws.ws_ext_sales_price)                AS total_sales,
  SUM(cr.cr_return_amount)                 AS total_return_amount,
  SUM(inv.inv_quantity_on_hand)            AS total_inventory_qty,
  COUNT(DISTINCT ws.ws_order_number)       AS distinct_orders,
  AVG(ws.ws_ext_discount_amt)              AS avg_discount,
  MAX(ws.ws_net_profit)                    AS max_net_profit,
  MIN(cr.cr_net_loss)                      AS min_net_loss
FROM web_sales ws
RIGHT OUTER JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
INNER JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
INNER JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN warehouse w_warehouse
  ON ws.ws_warehouse_sk = w_warehouse.w_warehouse_sk
INNER JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
/* catalog_returns linked to the same ship mode and warehouse as the sales rows */
INNER JOIN catalog_returns cr
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  AND cr.cr_warehouse_sk = w_warehouse.w_warehouse_sk
INNER JOIN date_dim d_ret
  ON cr.cr_returned_date_sk = d_ret.d_date_sk
INNER JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
INNER JOIN customer_address ca_refund
  ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
/* inventory linked via the same warehouse */
INNER JOIN inventory inv
  ON inv.inv_warehouse_sk = w_warehouse.w_warehouse_sk
INNER JOIN date_dim d_inv
  ON inv.inv_date_sk = d_inv.d_date_sk
WHERE
  d_sold.d_year = 2001                         -- filter by sales year
  AND wsite.web_state = 'CA'                    -- keep sites in California
  AND ca_refund.ca_county = 'Perry County'      -- refunded address county filter
  AND sm.sm_type = 'AIR'                        -- ship mode type filter
  AND r.r_reason_desc = 'Damaged'               -- return reason filter
  AND inv.inv_quantity_on_hand > 100            -- inventory stock filter
  AND ws.ws_quantity >= 2                       -- only orders with at least 2 items
GROUP BY
  wsite.web_site_id,
  d_sold.d_year,
  w_warehouse.w_warehouse_name,
  sm.sm_type,
  r.r_reason_desc
LIMIT 100
