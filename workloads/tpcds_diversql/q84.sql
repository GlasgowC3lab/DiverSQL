WITH
  catalog_data AS (
    SELECT
      cs.cs_order_number               AS order_number,
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_item_sk,
      cs.cs_quantity,
      cs.cs_net_paid,
      cp.cp_department,
      i.i_category,
      w.w_warehouse_name,
      sm.sm_type,
      cd.cd_gender,
      ca.ca_state,
      p.p_promo_name,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_net_loss,
      td.t_shift,
      td.t_am_pm,
      inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
   WHERE cs.cs_sold_date_sk BETWEEN 2451910 AND 2451919               -- predicate 1
     AND i.i_current_price > 20                                      -- predicate 2
     AND w.w_state = 'CA'                                            -- predicate 3
     AND sm.sm_type = 'AIR'                                          -- predicate 4
     AND p.p_discount_active = 'Y'                                   -- predicate 5
     AND cd.cd_gender = 'M'                                          -- predicate 6
     AND td.t_shift IN ('first', 'second')                           -- predicate 7
     AND td.t_am_pm = 'PM'                                           -- predicate 8
     AND p.p_channel_catalog = 'N'                                   -- predicate 9
     AND inv.inv_quantity_on_hand > 0                                -- predicate 10
  ),

  web_data AS (
    SELECT
      ws.ws_order_number               AS order_number,
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_item_sk,
      ws.ws_quantity,
      ws.ws_net_paid,
      i.i_category,
      w.w_warehouse_name,
      sm.sm_type,
      cd.cd_gender,
      ca.ca_state,
      p.p_promo_name,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      wr.wr_net_loss,
      td.t_shift,
      td.t_am_pm,
      inv.inv_quantity_on_hand
    FROM web_sales ws
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd
      ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN time_dim td
      ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
   WHERE ws.ws_sold_date_sk BETWEEN 2451910 AND 2451919               -- predicate 1
     AND i.i_current_price > 20                                      -- predicate 2
     AND w.w_state = 'CA'                                            -- predicate 3
     AND sm.sm_type = 'AIR'                                          -- predicate 4
     AND p.p_discount_active = 'Y'                                   -- predicate 5
     AND cd.cd_gender = 'F'                                          -- predicate 6
     AND td.t_shift IN ('first', 'second')                           -- predicate 7
     AND td.t_am_pm = 'PM'                                           -- predicate 8
     AND p.p_channel_catalog = 'N'                                   -- predicate 9
     AND inv.inv_quantity_on_hand > 0                                -- predicate 10
  )

SELECT
  order_number,
  ROW_NUMBER() OVER (ORDER BY order_number) AS rn
FROM (
  SELECT order_number FROM catalog_data
  EXCEPT
  SELECT order_number FROM web_data
) diff_orders
ORDER BY rn
LIMIT 100
