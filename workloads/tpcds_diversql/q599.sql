WITH
  sample_inventory AS (
    SELECT *
    FROM inventory
    TABLESAMPLE BERNOULLI (10)  -- sample 10% of inventory rows
  ),
  catalog_sales_filtered AS (
    SELECT
      cs.cs_order_number,
      cs.cs_quantity,
      cs.cs_net_paid,
      cs.cs_ext_sales_price,
      cs.cs_sold_time_sk,
      cs.cs_item_sk,
      cs.cs_warehouse_sk,
      c.c_customer_id,
      cd.cd_gender,
      i.i_item_id,
      i.i_current_price,
      w.w_warehouse_name,
      sm.sm_type,
      t.t_hour
    FROM catalog_sales cs
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE cs.cs_quantity > 5
      AND i.i_current_price BETWEEN 10 AND 1000
      AND w.w_state = 'CA'
  ),
  web_sales_filtered AS (
    SELECT
      ws.ws_order_number,
      ws.ws_quantity,
      ws.ws_net_paid,
      ws.ws_ext_sales_price,
      ws.ws_sold_time_sk,
      ws.ws_item_sk,
      ws.ws_warehouse_sk,
      c.c_customer_id AS ws_customer_id,
      cd.cd_gender AS ws_gender,
      i.i_item_id AS ws_item_id,
      i.i_current_price AS ws_item_price,
      w.w_warehouse_name AS ws_warehouse_name,
      sm.sm_type AS ws_ship_type,
      t.t_hour AS ws_hour,
      site.web_name AS ws_site_name
    FROM web_sales ws
    JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t
      ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_site site
      ON ws.ws_web_site_sk = site.web_site_sk
    WHERE ws.ws_quantity >= 3
      AND i.i_current_price < 500
  ),
  catalog_returns_joined AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_amount,
      cr.cr_return_ship_cost,
      r.r_reason_desc,
      cp.cp_department,
      i.i_item_id AS cr_item_id
    FROM catalog_returns cr
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_return_amount > 100
  ),
  web_returns_joined AS (
    SELECT
      wr.wr_order_number,
      wr.wr_return_amt,
      wr.wr_return_ship_cost,
      r.r_reason_desc AS wr_reason_desc,
      wp.wp_url
    FROM web_returns wr
    JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_return_amt > 50
  ),
  order_numbers_union AS (
    SELECT cs_order_number AS order_number
    FROM catalog_sales_filtered
    WHERE cs_net_paid > 500
    UNION
    SELECT ws_order_number
    FROM web_sales_filtered
    WHERE ws_net_paid > 400
  ),
  order_numbers_common AS (
    SELECT order_number FROM order_numbers_union
    INTERSECT
    SELECT cr_order_number FROM catalog_returns_joined
    INTERSECT
    SELECT wr_order_number FROM web_returns_joined
  ),
  final AS (
    SELECT
      cs.cs_order_number,
      cs.c_customer_id,
      i.i_item_id,
      w.w_warehouse_name,
      cs.cs_ext_sales_price,
      cr.cr_return_amount,
      ws.ws_ext_sales_price,
      wr.wr_return_amt,
      ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY cs.cs_ext_sales_price DESC) AS rn
    FROM catalog_sales_filtered cs
    JOIN sample_inventory inv
      ON cs.cs_item_sk = inv.inv_item_sk
     AND cs.cs_warehouse_sk = inv.inv_warehouse_sk
    JOIN catalog_returns_joined cr
      ON cs.cs_order_number = cr.cr_order_number
    JOIN web_sales_filtered ws
      ON cs.cs_order_number = ws.ws_order_number
    JOIN web_returns_joined wr
      ON cs.cs_order_number = wr.wr_order_number
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_order_number IN (SELECT order_number FROM order_numbers_common)
      AND EXISTS (
        SELECT 1
        FROM time_dim t
        WHERE t.t_time_sk = cs.cs_sold_time_sk
          AND t.t_hour BETWEEN 8 AND 18
      )
  )
SELECT
  cs_order_number,
  c_customer_id,
  i_item_id,
  w_warehouse_name,
  cs_ext_sales_price,
  cr_return_amount,
  ws_ext_sales_price,
  wr_return_amt,
  rn
FROM final
WHERE rn <= 10
ORDER BY w_warehouse_name, rn
LIMIT 100
