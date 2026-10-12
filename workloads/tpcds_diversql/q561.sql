WITH
  wp_ws_full AS (
    SELECT
      wp.wp_web_page_sk,
      wp.wp_url,
      ws.web_site_sk,
      ws.web_name,
      COALESCE(wp.d_date_sk, ws.d_date_sk) AS d_date_sk
    FROM (
      SELECT wp.wp_web_page_sk, wp.wp_url, d1.d_date_sk
      FROM web_page wp
      JOIN date_dim d1 ON wp.wp_creation_date_sk = d1.d_date_sk
    ) wp
    FULL OUTER JOIN (
      SELECT ws.web_site_sk, ws.web_name, d2.d_date_sk
      FROM web_site ws
      JOIN date_dim d2 ON ws.web_open_date_sk = d2.d_date_sk
    ) ws ON wp.d_date_sk = ws.d_date_sk
  ),

  orders_without_returns AS (
    SELECT cs_order_number
    FROM catalog_sales
    EXCEPT
    SELECT cr_order_number
    FROM catalog_returns
  ),

  base AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_item_sk,
      cs.cs_quantity,
      cs.cs_net_paid,
      c.c_customer_sk,
      ca.ca_state,
      cd.cd_gender,
      d.d_year,
      i.i_brand,
      i.i_category,
      sm.sm_carrier,
      w.w_state,
      w.w_warehouse_sk,
      r.r_reason_desc,
      ss.ss_quantity AS ss_qty,
      inv.inv_quantity_on_hand,
      wp_ws.d_date_sk AS wp_ws_date_sk
    FROM call_center cc
    JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                               AND inv.inv_warehouse_sk = w.w_warehouse_sk
                               AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
                               AND ss.ss_sold_date_sk = d.d_date_sk
                               AND ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN wp_ws_full wp_ws ON wp_ws.d_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#23'
      AND sm.sm_carrier = 'DHL'
      AND w.w_state = 'CA'
      AND c.c_preferred_cust_flag = 'Y'
      AND r.r_reason_desc LIKE '%reorder%'
      AND cs.cs_quantity > 5
  ),

  inv_lateral AS (
    SELECT
      b.*, 
      inv_sum.total_inv_qty
    FROM base b
    LEFT JOIN LATERAL (
      SELECT SUM(inv_quantity_on_hand) AS total_inv_qty
      FROM inventory inv
      WHERE inv.inv_item_sk = b.cs_item_sk
        AND inv.inv_warehouse_sk = b.w_warehouse_sk
    ) inv_sum ON TRUE
  )
SELECT
  il.d_year,
  il.i_brand,
  COUNT(DISTINCT il.c_customer_sk) AS distinct_customers,
  COUNT(DISTINCT il.cs_item_sk) AS distinct_items,
  SUM(il.cs_net_paid) AS total_net_paid,
  AVG(il.total_inv_qty) AS avg_total_inventory,
  SUM(COALESCE(il.inv_quantity_on_hand, 0)) AS total_on_hand
FROM inv_lateral il
WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = il.cs_order_number
          AND cr2.cr_return_quantity > 0
      )
  AND il.cs_order_number IN (SELECT cs_order_number FROM orders_without_returns)
GROUP BY il.d_year, il.i_brand
HAVING SUM(il.cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
