WITH
  inv_agg AS (
    SELECT
      inv_warehouse_sk,
      SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
  ),
  base_agg AS (
    SELECT
      s.s_store_name,
      w.w_warehouse_name,
      cp.cp_type,
      i.i_item_id,
      SUM(ws.ws_net_profit) AS total_net_profit,
      SUM(cr.cr_return_amount) AS total_catalog_return_amount,
      SUM(sr.sr_net_loss) AS total_store_return_loss,
      SUM(wr.wr_net_loss) AS total_web_return_loss,
      inv_agg.total_on_hand
    FROM
      web_sales ws
      JOIN item i ON ws.ws_item_sk = i.i_item_sk
      JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
      JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
      JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
      JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
      JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
      JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
      JOIN customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
      JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
      JOIN customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
      JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
      JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
      JOIN reason cr_r ON cr.cr_reason_sk = cr_r.r_reason_sk
      LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
      LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
      LEFT JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
      LEFT JOIN reason sr_r ON sr.sr_reason_sk = sr_r.r_reason_sk
      LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
      LEFT JOIN web_page wp_ws ON ws.ws_web_page_sk = wp_ws.wp_web_page_sk
      LEFT JOIN web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
      LEFT JOIN reason wr_r ON wr.wr_reason_sk = wr_r.r_reason_sk
      LEFT JOIN inv_agg ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
      cp.cp_type = 'monthly'
      AND s.s_market_desc LIKE '%Round%'
      AND i.i_current_price > 50
    GROUP BY
      GROUPING SETS (
        (s.s_store_name, w.w_warehouse_name, cp.cp_type, i.i_item_id, inv_agg.total_on_hand),
        (s.s_store_name, w.w_warehouse_name, cp.cp_type, inv_agg.total_on_hand),
        (w.w_warehouse_name, cp.cp_type, i.i_item_id, inv_agg.total_on_hand),
        (cp.cp_type, i.i_item_id, inv_agg.total_on_hand)
      )
  )
SELECT
  s_store_name,
  w_warehouse_name,
  cp_type,
  i_item_id,
  total_net_profit,
  total_catalog_return_amount,
  total_store_return_loss,
  total_web_return_loss,
  total_on_hand,
  RANK() OVER (PARTITION BY cp_type ORDER BY total_net_profit DESC) AS profit_rank
FROM base_agg
ORDER BY total_net_profit DESC
LIMIT 100
