WITH
  inv_agg AS (
    SELECT
      inv_item_sk,
      inv_warehouse_sk,
      SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
  ),
  item_not_in_catalog AS (
    SELECT inv_item_sk AS i_item_sk
    FROM inventory
    EXCEPT
    SELECT cs_item_sk FROM catalog_sales
  ),
  store_branch AS (
    SELECT
      i.i_item_sk,
      i.i_product_name,
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      td.t_time AS time_indicator,
      SUM(ss.ss_net_paid)               AS store_sales_net,
      SUM(sr.sr_return_amt)             AS store_returns_amt,
      SUM(cs.cs_net_paid)               AS catalog_sales_net,
      SUM(cs.cs_ext_discount_amt)       AS catalog_discount,
      CAST(NULL AS decimal(7,2))        AS web_sales_net,
      CAST(NULL AS decimal(7,2))        AS web_returns_amt,
      sm.sm_type                         AS ship_mode_type,
      w.w_warehouse_name                 AS warehouse_name,
      inv_agg.total_qty                  AS total_qty,
      (SELECT COUNT(*) FROM promotion p2 WHERE p2.p_item_sk = i.i_item_sk) AS promo_cnt,
      CAST(NULL AS varchar)             AS web_page_id,
      CAST(NULL AS varchar)             AS web_site_name
    FROM item i
    LEFT JOIN store_sales ss      ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr   ON sr.sr_item_sk = i.i_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN catalog_sales cs   ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN customer c         ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN time_dim td        ON ss.ss_sold_time_sk = td.t_time_sk
    LEFT JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN ship_mode sm       ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inv_agg ON inv_agg.inv_item_sk = i.i_item_sk
    GROUP BY GROUPING SETS (
      (i.i_item_sk, i.i_product_name, c.c_customer_sk, c.c_first_name, c.c_last_name, td.t_time, sm.sm_type, w.w_warehouse_name, inv_agg.total_qty),
      (i.i_item_sk, i.i_product_name),
      ()
    )
  ),
  web_branch AS (
    SELECT
      i.i_item_sk,
      i.i_product_name,
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      td.t_time AS time_indicator,
      CAST(NULL AS decimal(7,2))        AS store_sales_net,
      CAST(NULL AS decimal(7,2))        AS store_returns_amt,
      CAST(NULL AS decimal(7,2))        AS catalog_sales_net,
      CAST(NULL AS decimal(7,2))        AS catalog_discount,
      SUM(ws.ws_net_paid)               AS web_sales_net,
      SUM(wr.wr_return_amt)             AS web_returns_amt,
      sm2.sm_type                       AS ship_mode_type,
      w2.w_warehouse_name                AS warehouse_name,
      inv_agg2.total_qty                 AS total_qty,
      (SELECT COUNT(*) FROM promotion p2 WHERE p2.p_item_sk = i.i_item_sk) AS promo_cnt,
      wp.wp_web_page_id                 AS web_page_id,
      we.web_name                       AS web_site_name
    FROM item i
    LEFT JOIN web_sales ws       ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr    ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN customer c         ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN time_dim td        ON ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN web_page wp        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site we        ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN ship_mode sm2      ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    LEFT JOIN warehouse w2       ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    LEFT JOIN inv_agg AS inv_agg2 ON inv_agg2.inv_item_sk = i.i_item_sk
    GROUP BY GROUPING SETS (
      (i.i_item_sk, i.i_product_name, c.c_customer_sk, c.c_first_name, c.c_last_name, td.t_time, sm2.sm_type, w2.w_warehouse_name, inv_agg2.total_qty, wp.wp_web_page_id, we.web_name),
      (i.i_item_sk, i.i_product_name),
      ()
    )
  )
SELECT
  final.i_item_sk,
  final.i_product_name,
  final.c_customer_sk,
  final.c_first_name,
  final.c_last_name,
  final.time_indicator,
  final.store_sales_net,
  final.store_returns_amt,
  final.catalog_sales_net,
  final.catalog_discount,
  final.web_sales_net,
  final.web_returns_amt,
  final.ship_mode_type,
  final.warehouse_name,
  final.total_qty,
  final.promo_cnt,
  final.web_page_id,
  final.web_site_name,
  (final.store_sales_net + final.web_sales_net) AS total_sales_net,
  LAG(final.store_sales_net + final.web_sales_net) OVER (PARTITION BY final.i_item_sk ORDER BY final.time_indicator) AS prev_sales,
  ROW_NUMBER() OVER (ORDER BY (final.store_sales_net + final.web_sales_net) DESC) AS row_num
FROM (
  SELECT * FROM store_branch
  UNION DISTINCT
  SELECT * FROM web_branch
) AS final
WHERE final.i_item_sk IN (SELECT i_item_sk FROM item_not_in_catalog)
ORDER BY total_sales_net DESC
LIMIT 100
