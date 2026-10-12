WITH
  inventory_agg AS (
    SELECT
      inv_item_sk,
      inv_warehouse_sk,
      SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
  ),
  joined_data AS (
    SELECT
      c.c_customer_id,
      c.c_email_address,
      i.i_item_id,
      i.i_product_name,
      s.s_store_name,
      w.w_warehouse_name,
      wp.wp_url,
      td.t_hour,
      ib.ib_income_band_sk,
      ia.total_qty_on_hand,
      ss.ss_net_paid AS ss_net_paid,
      cs.cs_net_paid AS cs_net_paid,
      ws.ws_net_paid AS ws_net_paid,
      sr.sr_return_quantity,
      cr.cr_return_quantity,
      wr.wr_return_quantity
    FROM inventory_agg ia
    JOIN item i ON ia.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON ia.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE i.i_current_price > 50
      AND c.c_email_address LIKE '%@%org'
      AND w.w_state = 'CA'
      AND NOT EXISTS (
        SELECT 1 FROM catalog_returns crx WHERE crx.cr_order_number = cs.cs_order_number
      )
  ),
  aggregated_sales AS (
    SELECT
      c_customer_id,
      c_email_address,
      i_item_id,
      i_product_name,
      s_store_name,
      w_warehouse_name,
      wp_url,
      t_hour,
      ib_income_band_sk,
      total_qty_on_hand,
      SUM(ss_net_paid + cs_net_paid + ws_net_paid) AS total_net_paid
    FROM joined_data
    GROUP BY
      c_customer_id,
      c_email_address,
      i_item_id,
      i_product_name,
      s_store_name,
      w_warehouse_name,
      wp_url,
      t_hour,
      ib_income_band_sk,
      total_qty_on_hand
  )
SELECT * FROM (
  SELECT
    c_customer_id,
    c_email_address,
    i_item_id,
    i_product_name,
    s_store_name,
    w_warehouse_name,
    wp_url,
    t_hour,
    total_qty_on_hand,
    total_net_paid,
    ROW_NUMBER() OVER (PARTITION BY ib_income_band_sk ORDER BY total_net_paid DESC) AS rank_in_income_band
  FROM aggregated_sales
  WHERE t_hour BETWEEN 9 AND 12

  UNION

  SELECT
    c_customer_id,
    c_email_address,
    i_item_id,
    i_product_name,
    s_store_name,
    w_warehouse_name,
    wp_url,
    t_hour,
    total_qty_on_hand,
    total_net_paid,
    ROW_NUMBER() OVER (PARTITION BY ib_income_band_sk ORDER BY total_net_paid DESC) AS rank_in_income_band
  FROM aggregated_sales
  WHERE t_hour BETWEEN 13 AND 16
) AS final_result
ORDER BY total_net_paid DESC, rank_in_income_band
LIMIT 100
