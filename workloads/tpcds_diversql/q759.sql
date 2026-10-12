WITH cs AS (
   SELECT
      cs.cs_order_number,
      cs.cs_net_paid,
      cs.cs_net_profit,
      cs.cs_item_sk,
      i.i_item_id,
      i.i_category,
      i.i_current_price,
      i.i_item_desc,
      cp.cp_catalog_page_id,
      sm.sm_type,
      ca.ca_state,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      td.t_hour,
      CASE WHEN i.i_current_price > 100 THEN 'high' ELSE 'medium' END AS price_category
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
   WHERE cs.cs_net_paid > 1000
     AND td.t_hour BETWEEN 9 AND 17
     AND ca.ca_state = 'CA'
     AND i.i_category = 'Electronics'
),

ws AS (
   SELECT
      ws.ws_order_number,
      ws.ws_net_paid,
      ws.ws_item_sk,
      i.i_item_id,
      i.i_category,
      i.i_current_price,
      i.i_item_desc,
      wp.wp_type,
      sm.sm_type AS ship_mode,
      td.t_hour AS hour
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
   WHERE ws.ws_net_paid > 500
     AND wp.wp_type = 'Content'
     AND td.t_hour >= 12
),

sr AS (
   SELECT
      sr.sr_ticket_number,
      sr.sr_return_amt,
      sr.sr_item_sk,
      i.i_item_id,
      i.i_category,
      i.i_current_price,
      i.i_item_desc,
      st.s_store_name,
      r.r_reason_desc,
      td.t_hour AS hour
   FROM store_returns sr
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN store st ON sr.sr_store_sk = st.s_store_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
   WHERE sr.sr_return_amt > 0
     AND st.s_state = 'TX'
),

inv AS (
   SELECT
      inv.inv_item_sk,
      inv.inv_quantity_on_hand,
      i.i_item_id
   FROM inventory inv
   JOIN item i ON inv.inv_item_sk = i.i_item_sk
   WHERE inv.inv_quantity_on_hand < 100
),

fo AS (
   SELECT
      COALESCE(cs.cs_item_sk, ws.ws_item_sk) AS item_sk,
      cs.cs_order_number,
      cs.cs_net_paid,
      cs.cs_net_profit,
      ws.ws_order_number,
      ws.ws_net_paid
   FROM cs
   FULL OUTER JOIN ws ON cs.cs_item_sk = ws.ws_item_sk
),

order_numbers_cs AS (
   SELECT cs_order_number FROM cs
),

order_numbers_ws AS (
   SELECT ws_order_number FROM ws
),

high_profit_orders AS (
   SELECT cs_order_number FROM cs WHERE cs.cs_net_profit > 5000
)

SELECT
   itm.i_item_id               AS item_id,
   itm.i_category              AS category,
   cs.price_category,
   SUM(fo.cs_net_paid)         AS total_cs_paid,
   SUM(fo.ws_net_paid)         AS total_ws_paid,
   SUM(sr.sr_return_amt)       AS total_returns,
   MIN(inv.inv_quantity_on_hand) AS min_inventory,
   COUNT(DISTINCT fo.cs_order_number) AS cs_order_cnt,
   CASE
      WHEN SUM(cs.cs_net_profit) > 10000 THEN 'Very Profitable'
      ELSE 'Normal'
   END                         AS profitability_flag,
   (SELECT AVG(cs_net_paid) FROM catalog_sales) AS avg_catalog_paid,
   w.word                      AS item_word
FROM item itm
LEFT JOIN fo   ON fo.item_sk   = itm.i_item_sk
LEFT JOIN cs   ON cs.cs_item_sk = itm.i_item_sk
LEFT JOIN ws   ON ws.ws_item_sk = itm.i_item_sk
LEFT JOIN sr   ON sr.sr_item_sk = itm.i_item_sk
LEFT JOIN inv  ON inv.inv_item_sk = itm.i_item_sk
-- expand the item description into individual words
LEFT JOIN LATERAL (
   SELECT word
   FROM UNNEST(split(itm.i_item_desc, ' ')) AS t(word)
) w ON true
WHERE fo.cs_order_number IN (
      SELECT cs_order_number FROM order_numbers_cs
      INTERSECT
      SELECT ws_order_number FROM order_numbers_ws
      EXCEPT
      SELECT cs_order_number FROM high_profit_orders
)
GROUP BY
   itm.i_item_id,
   itm.i_category,
   cs.price_category,
   w.word
HAVING COUNT(*) > 1
ORDER BY total_cs_paid DESC
LIMIT 100
