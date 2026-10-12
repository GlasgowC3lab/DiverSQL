/* goal: Identify the top 100 items by combined net profit from store and web sales, excluding items that have any returns and only considering items that are in stock. The query ranks items, applies multiple filters, uses DISTINCT, a window function, and an EXCEPT set operation. */
WITH
  store_agg AS (
    SELECT
      i.i_item_id,
      SUM(ss.ss_net_profit) AS store_net_profit,
      SUM(ss.ss_quantity) AS store_quantity,
      COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE i.i_current_price > 50
      AND p.p_cost < 5000
      AND hd.hd_income_band_sk IN (2, 9, 15)
      AND cd.cd_gender = 'M'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_item_id
  ),
  web_agg AS (
    SELECT
      i.i_item_id,
      SUM(ws.ws_net_profit) AS web_net_profit,
      SUM(ws.ws_quantity) AS web_quantity,
      COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE i.i_current_price > 50
      AND p.p_cost < 5000
      AND hd.hd_income_band_sk IN (2, 9, 15)
      AND cd.cd_gender = 'M'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_item_id
  ),
  combined AS (
    SELECT
      COALESCE(s.i_item_id, w.i_item_id) AS i_item_id,
      s.store_net_profit,
      w.web_net_profit,
      COALESCE(s.store_net_profit, 0) + COALESCE(w.web_net_profit, 0) AS total_net_profit,
      ROW_NUMBER() OVER (ORDER BY COALESCE(s.store_net_profit, 0) + COALESCE(w.web_net_profit, 0) DESC) AS rn
    FROM store_agg s
    FULL OUTER JOIN web_agg w ON s.i_item_id = w.i_item_id
  ),
  inventory_items AS (
    SELECT i.i_item_id
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_quantity_on_hand > 0
  ),
  returns_items AS (
    SELECT DISTINCT i.i_item_id
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    UNION
    SELECT DISTINCT i.i_item_id
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    UNION
    SELECT DISTINCT i.i_item_id
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  )
SELECT DISTINCT
  c.i_item_id,
  c.store_net_profit,
  c.web_net_profit,
  c.total_net_profit,
  c.rn
FROM combined c
WHERE c.i_item_id IN (
        SELECT i_item_id FROM inventory_items
        EXCEPT
        SELECT i_item_id FROM returns_items
      )
  AND c.rn <= 100
ORDER BY c.total_net_profit DESC
LIMIT 100
