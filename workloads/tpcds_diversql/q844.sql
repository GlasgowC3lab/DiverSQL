WITH
  sales_agg AS (
    SELECT
      cs_call_center_sk,
      cs_catalog_page_sk,
      cs_warehouse_sk,
      cs_ship_mode_sk,
      cs_sold_date_sk,
      SUM(cs_ext_sales_price) AS sum_sales,
      SUM(cs_quantity) AS sum_qty,
      AVG(cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales
    WHERE cs_ext_sales_price > 500
      AND cs_quantity >= 1
      AND cs_list_price BETWEEN 100 AND 200
    GROUP BY
      cs_call_center_sk,
      cs_catalog_page_sk,
      cs_warehouse_sk,
      cs_ship_mode_sk,
      cs_sold_date_sk
  ),
  returns_agg AS (
    SELECT
      cr_call_center_sk,
      cr_catalog_page_sk,
      cr_warehouse_sk,
      cr_ship_mode_sk,
      cr_returned_date_sk,
      SUM(cr_return_amount) AS sum_return,
      SUM(cr_return_quantity) AS sum_return_qty
    FROM catalog_returns
    WHERE cr_return_amount > 0
      AND cr_return_quantity > 0
    GROUP BY
      cr_call_center_sk,
      cr_catalog_page_sk,
      cr_warehouse_sk,
      cr_ship_mode_sk,
      cr_returned_date_sk
  ),
  combined AS (
    SELECT
      sa.cs_call_center_sk,
      sa.cs_catalog_page_sk,
      sa.cs_warehouse_sk,
      sa.cs_ship_mode_sk,
      sa.cs_sold_date_sk,
      sa.sum_sales,
      sa.sum_qty,
      sa.avg_discount,
      ra.sum_return,
      ra.sum_return_qty
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
      ON sa.cs_call_center_sk = ra.cr_call_center_sk
     AND sa.cs_catalog_page_sk = ra.cr_catalog_page_sk
     AND sa.cs_warehouse_sk = ra.cr_warehouse_sk
     AND sa.cs_ship_mode_sk = ra.cr_ship_mode_sk
     AND sa.cs_sold_date_sk = ra.cr_returned_date_sk
    WHERE ra.sum_return IS NOT NULL
  ),
  combined_lateral AS (
    SELECT
      c.*, 
      (c.sum_sales - COALESCE(c.sum_return, 0)) AS net_sales,
      (c.sum_sales - COALESCE(c.sum_return, 0)) / NULLIF(c.sum_qty, 0) AS net_per_qty
    FROM combined c
  ),
  date_filtered AS (
    SELECT
      cl.*, 
      d.d_year,
      d.d_month_seq,
      d.d_day_name
    FROM combined_lateral cl
    JOIN date_dim d
      ON cl.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq = 1201
  ),
  branch_a AS (
    SELECT
      w.w_warehouse_id,
      w.w_city,
      w.w_state,
      cc.cc_name,
      cp.cp_description,
      sm.sm_carrier,
      df.net_sales,
      df.avg_discount,
      df.net_per_qty,
      d.d_year,
      lt.net_per_qty_lateral
    FROM date_filtered df
    JOIN warehouse w
      ON df.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc
      ON df.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
      ON df.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON df.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d
      ON df.cs_sold_date_sk = d.d_date_sk
    CROSS JOIN LATERAL (
      SELECT ROUND(df.net_sales / NULLIF(df.sum_qty, 0), 2) AS net_per_qty_lateral
    ) lt
    WHERE cc.cc_division = 3
      AND cp.cp_type = 'Page'
      AND sm.sm_type = 'AIR'
      AND w.w_warehouse_sq_ft > 15000
  ),
  branch_b AS (
    SELECT
      w.w_warehouse_id,
      w.w_city,
      w.w_state,
      cc.cc_name,
      cp.cp_description,
      sm.sm_carrier,
      df.net_sales,
      df.avg_discount,
      df.net_per_qty,
      d.d_year,
      lt.net_per_qty_lateral
    FROM date_filtered df
    JOIN warehouse w
      ON df.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc
      ON df.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
      ON df.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON df.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d
      ON df.cs_sold_date_sk = d.d_date_sk
    CROSS JOIN LATERAL (
      SELECT ROUND(df.net_sales / NULLIF(df.sum_qty, 0), 2) AS net_per_qty_lateral
    ) lt
    WHERE cc.cc_division = 4
      AND cp.cp_department = 'Books'
      AND sm.sm_carrier = 'UPS'
      AND w.w_state = 'CA'
  ),
  unioned AS (
    SELECT DISTINCT * FROM branch_a
    UNION
    SELECT DISTINCT * FROM branch_b
  ),
  intersected AS (
    SELECT w_warehouse_id FROM branch_a
    INTERSECT
    SELECT w_warehouse_id FROM branch_b
  )
SELECT
  u.w_warehouse_id,
  u.w_city,
  u.w_state,
  u.cc_name,
  u.cp_description,
  u.sm_carrier,
  u.net_sales,
  u.avg_discount,
  ROUND(u.net_per_qty, 2) AS net_per_qty,
  u.d_year
FROM unioned u
WHERE u.w_warehouse_id IN (SELECT w_warehouse_id FROM intersected)
ORDER BY u.net_sales DESC
LIMIT 100
