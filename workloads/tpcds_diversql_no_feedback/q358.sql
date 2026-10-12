/*
Goal: Aggregate sales and return amounts by item category across the catalog, store, and web channels. The query retains every ship mode (right outer join), filters items to those appearing in high‑quantity web sales, reuses the customer and time dimensions under multiple aliases, and reports both per‑category and grand‑total rows using GROUPING SETS.
*/
WITH
  /* Time dimensions used for different roles */
  td_sold AS (
    SELECT t_time_sk, t_hour
    FROM time_dim
  ),
  td_return AS (
    SELECT t_time_sk, t_hour
    FROM time_dim
  ),
  td_web AS (
    SELECT t_time_sk, t_hour
    FROM time_dim
  ),

  /* Items that have appeared in a web sale with quantity > 5 */
  filtered_items AS (
    SELECT i_item_sk, i_category, i_brand, i_product_name
    FROM item
    WHERE i_item_sk IN (
      SELECT ws_item_sk
      FROM web_sales
      WHERE ws_quantity > 5
    )
  ),

  /* Catalog sales with many dimension joins – ship_mode is right‑joined to keep all ship modes */
  cs_join AS (
    SELECT
      cs.cs_order_number,
      cs.cs_ext_sales_price      AS sales_amount,
      cs.cs_net_profit           AS profit,
      td_sold.t_hour              AS sale_hour,
      cust_bill.c_customer_id    AS bill_cust_id,
      cust_ship.c_customer_id    AS ship_cust_id,
      hd_bill.hd_buy_potential   AS bill_buy_pot,
      hd_ship.hd_buy_potential   AS ship_buy_pot,
      ca_bill.ca_state           AS bill_state,
      ca_ship.ca_state           AS ship_state,
      sm.sm_type                  AS ship_type,
      wh.w_warehouse_name        AS warehouse_name,
      fi.i_category               AS category,
      fi.i_brand                  AS brand
    FROM catalog_sales cs
    LEFT JOIN time_dim td_sold
      ON cs.cs_sold_time_sk = td_sold.t_time_sk
    LEFT JOIN customer cust_bill
      ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    LEFT JOIN customer cust_ship
      ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
    LEFT JOIN household_demographics hd_bill
      ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    LEFT JOIN household_demographics hd_ship
      ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    LEFT JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN customer_address ca_ship
      ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    RIGHT JOIN ship_mode sm                     -- retain every ship mode
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse wh
      ON cs.cs_warehouse_sk = wh.w_warehouse_sk
    LEFT JOIN filtered_items fi
      ON cs.cs_item_sk = fi.i_item_sk
  ),

  /* Store returns */
  sr_join AS (
    SELECT
      sr.sr_ticket_number          AS order_number,
      sr.sr_return_amt             AS return_amount,
      -sr.sr_return_amt            AS profit,
      td_return.t_hour             AS return_hour,
      cust.c_customer_id           AS ret_cust_id,
      hd.hd_buy_potential          AS buy_pot,
      ca.ca_state                  AS state,
      st.s_store_name              AS store_name,
      i.i_category                 AS category
    FROM store_returns sr
    LEFT JOIN time_dim td_return
      ON sr.sr_return_time_sk = td_return.t_time_sk
    LEFT JOIN customer cust
      ON sr.sr_customer_sk = cust.c_customer_sk
    LEFT JOIN household_demographics hd
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_address ca
      ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN store st
      ON sr.sr_store_sk = st.s_store_sk
    LEFT JOIN item i
      ON sr.sr_item_sk = i.i_item_sk
  ),

  /* Web sales */
  ws_join AS (
    SELECT
      ws.ws_order_number           AS order_number,
      ws.ws_ext_sales_price        AS sales_amount,
      ws.ws_net_profit             AS profit,
      td_web.t_hour                AS web_sale_hour,
      cust_ws.c_customer_id        AS bill_cust_id,
      hd_ws.hd_buy_potential        AS bill_buy_pot,
      ca_ws.ca_state               AS bill_state,
      wp.wp_type                   AS web_page_type,
      sm_ws.sm_type                AS ship_type,
      wh_ws.w_warehouse_name       AS warehouse_name,
      i_ws.i_category              AS category
    FROM web_sales ws
    LEFT JOIN time_dim td_web
      ON ws.ws_sold_time_sk = td_web.t_time_sk
    LEFT JOIN customer cust_ws
      ON ws.ws_bill_customer_sk = cust_ws.c_customer_sk
    LEFT JOIN household_demographics hd_ws
      ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    LEFT JOIN customer_address ca_ws
      ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
    LEFT JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN ship_mode sm_ws
      ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    LEFT JOIN warehouse wh_ws
      ON ws.ws_warehouse_sk = wh_ws.w_warehouse_sk
    LEFT JOIN item i_ws
      ON ws.ws_item_sk = i_ws.i_item_sk
  ),

  /* Web returns */
  wr_join AS (
    SELECT
      wr.wr_return_quantity       AS return_qty,
      wr.wr_return_amt            AS return_amount,
      -wr.wr_return_amt           AS profit,
      td_web.t_hour               AS web_ret_hour,
      cust_ref.c_customer_id      AS refunded_cust_id,
      cust_ret.c_customer_id      AS returning_cust_id,
      wp.wp_type                  AS web_page_type,
      i_wr.i_category             AS category,
      wr.wr_order_number          AS order_number
    FROM web_returns wr
    LEFT JOIN time_dim td_web
      ON wr.wr_returned_time_sk = td_web.t_time_sk
    LEFT JOIN customer cust_ref
      ON wr.wr_refunded_customer_sk = cust_ref.c_customer_sk
    LEFT JOIN customer cust_ret
      ON wr.wr_returning_customer_sk = cust_ret.c_customer_sk
    LEFT JOIN household_demographics hd_ref
      ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    LEFT JOIN customer_address ca_ref
      ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    LEFT JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN item i_wr
      ON wr.wr_item_sk = i_wr.i_item_sk
    LEFT JOIN web_sales ws
      ON wr.wr_order_number = ws.ws_order_number
  )

/* Combine the four streams (catalog sales, store returns, web sales, web returns) */
SELECT
  GROUPING(category)                AS grouping_id,
  category,
  SUM(sales_amount)                 AS total_sales,
  SUM(return_amount)                AS total_returns,
  SUM(profit)                       AS total_profit,
  COUNT(DISTINCT order_number)      AS orders_cnt
FROM (
  SELECT
    cs_order_number   AS order_number,
    sales_amount,
    0.0               AS return_amount,
    profit,
    category
  FROM cs_join

  UNION ALL

  SELECT
    order_number,
    0.0               AS sales_amount,
    return_amount,
    profit,
    category
  FROM sr_join

  UNION ALL

  SELECT
    order_number,
    sales_amount,
    0.0               AS return_amount,
    profit,
    category
  FROM ws_join

  UNION ALL

  SELECT
    order_number,
    0.0               AS sales_amount,
    return_amount,
    profit,
    category
  FROM wr_join
) t
GROUP BY GROUPING SETS ( (category), () )
ORDER BY total_sales DESC, category
