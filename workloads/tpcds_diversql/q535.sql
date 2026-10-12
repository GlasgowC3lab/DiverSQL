WITH
  cs_base AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_item_sk,
      cs.cs_order_number,
      cs.cs_quantity,
      cs.cs_net_paid_inc_ship_tax,
      cs.cs_call_center_sk,
      cs.cs_ship_mode_sk,
      cs.cs_warehouse_sk,
      cc.cc_company_name,
      sm.sm_type,
      w.w_warehouse_name,
      t.t_hour,
      t.t_am_pm
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE cs.cs_quantity > 30
      AND cs.cs_net_paid_inc_ship_tax > 1000
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2459999
  ),
  cr_join AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_warehouse_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 1000
  ),
  ws_join AS (
    SELECT
      ws.ws_order_number,
      ws.ws_net_paid_inc_tax,
      ws.ws_ship_mode_sk,
      ws.ws_warehouse_sk,
      wp.wp_type
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_net_paid_inc_tax BETWEEN 500 AND 5000
  ),
  inv_join AS (
    SELECT
      inv.inv_warehouse_sk,
      SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    GROUP BY inv.inv_warehouse_sk
  ),
  -- Full outer join between catalog returns and inventory per warehouse
  cr_inv_full AS (
    SELECT
      cr.cr_warehouse_sk AS warehouse_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      i.total_on_hand
    FROM cr_join cr
    FULL OUTER JOIN inv_join i ON cr.cr_warehouse_sk = i.inv_warehouse_sk
  ),
  -- Orders that appear both in catalog sales and web sales
  common_orders AS (
    SELECT cs_order_number AS order_number FROM cs_base
    INTERSECT
    SELECT ws_order_number FROM ws_join
  ),
  -- Aggregate per warehouse, keeping rows that have at least one common order
  warehouse_agg AS (
    SELECT
      w.w_warehouse_sk,
      w.w_warehouse_name,
      SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales,
      SUM(cs.cs_quantity) AS total_quantity,
      COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
      SUM(COALESCE(cr_inv_full.cr_return_quantity, 0)) AS total_returns,
      SUM(COALESCE(cr_inv_full.total_on_hand, 0)) AS inventory_on_hand,
      SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_returns
    FROM cs_base cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN cr_inv_full ON w.w_warehouse_sk = cr_inv_full.warehouse_sk
    LEFT JOIN store_returns sr ON sr.sr_return_time_sk = cs.cs_sold_time_sk AND sr.sr_return_amt > 200
    WHERE EXISTS (
      SELECT 1 FROM common_orders co WHERE co.order_number = cs.cs_order_number
    )
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name
    HAVING SUM(cs.cs_net_paid_inc_ship_tax) > 5000
  )
SELECT
  wa.w_warehouse_name,
  wa.total_sales,
  wa.total_quantity,
  wa.distinct_orders,
  wa.total_returns,
  wa.inventory_on_hand,
  wa.total_store_returns,
  CASE WHEN wa.total_returns > 0 THEN wa.total_sales / wa.total_returns ELSE NULL END AS sales_per_return
FROM warehouse_agg wa
ORDER BY wa.total_sales DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
