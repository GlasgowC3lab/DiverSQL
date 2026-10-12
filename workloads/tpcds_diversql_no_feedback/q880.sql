/* Goal:  Analyze combined sales performance across catalog, web and store channels, filtered to items that appear in catalog sales but not in current inventory, for stores that have at least one return, using a sampled set of catalog pages. The query joins all 16 selected tables (with multiple aliases for date_dim), aggregates revenue by store, warehouse and web site, orders by catalog revenue and limits to 100 rows. */
WITH
  /* Items sold in catalog but not stocked in inventory */
  excl_items AS (
    SELECT cs_item_sk FROM catalog_sales
    EXCEPT
    SELECT inv_item_sk FROM inventory
  ),
  /* Sampled catalog pages */
  cp_sample AS (
    SELECT * FROM catalog_page TABLESAMPLE BERNOULLI (10)
  )
SELECT
  s.s_store_id,
  w.w_warehouse_name,
  wsit.web_name,
  d_sold.d_year,
  SUM(cs.cs_ext_sales_price)            AS total_catalog_sales,
  SUM(ws.ws_ext_sales_price)            AS total_web_sales,
  SUM(ss.ss_ext_sales_price)            AS total_store_sales,
  COUNT(DISTINCT cs.cs_order_number)    AS catalog_orders,
  COUNT(DISTINCT ws.ws_order_number)    AS web_orders,
  COUNT(DISTINCT ss.ss_ticket_number)   AS store_orders
FROM
  cp_sample                     cp
  JOIN catalog_sales            cs      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN excl_items               ei      ON cs.cs_item_sk = ei.cs_item_sk
  JOIN warehouse                w       ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer                 c       ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics    cd      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics   hd      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band              ib      ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN date_dim                 d_sold  ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN date_dim                 d_ship  ON cs.cs_ship_date_sk = d_ship.d_date_sk
  JOIN date_dim                 d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
  JOIN date_dim                 d_cp_end   ON cp.cp_end_date_sk   = d_cp_end.d_date_sk
  JOIN web_sales                ws      ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN web_page                 wp      ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN date_dim                 d_wp_create ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
  JOIN web_site                 wsit    ON ws.ws_web_site_sk = wsit.web_site_sk
  JOIN web_returns              wr      ON wr.wr_order_number = ws.ws_order_number
  JOIN store_sales              ss      ON ss.ss_customer_sk = c.c_customer_sk
  JOIN store                    s       ON ss.ss_store_sk = s.s_store_sk
  JOIN store_returns            sr      ON sr.sr_ticket_number = ss.ss_ticket_number
  JOIN date_dim                 d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
  JOIN inventory                inv     ON inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN date_dim                 d_inv   ON inv.inv_date_sk = d_inv.d_date_sk
WHERE
  EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_store_sk = s.s_store_sk
      AND sr2.sr_return_quantity > 0
  )
GROUP BY
  s.s_store_id,
  w.w_warehouse_name,
  wsit.web_name,
  d_sold.d_year
ORDER BY
  total_catalog_sales DESC
LIMIT 100
