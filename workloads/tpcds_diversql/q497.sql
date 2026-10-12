WITH excluded_store_keys AS (
   SELECT s.s_store_sk
   FROM store s
   WHERE s.s_state = 'NY'
   EXCEPT
   SELECT ss.ss_store_sk
   FROM store_sales ss
   WHERE ss.ss_quantity > 0
),
base AS (
   SELECT
       ss.ss_sold_date_sk,
       ss.ss_sold_time_sk,
       ss.ss_item_sk,
       ss.ss_store_sk,
       ss.ss_net_profit,
       td.t_meal_time,
       i.i_item_id,
       i.i_brand,
       s.s_store_name,
       s.s_state,
       w.w_warehouse_id,
       w.w_gmt_offset,
       r.r_reason_desc,
       inv.inv_quantity_on_hand,
       wr.wr_return_quantity,
       (
         SELECT SUM(inv2.inv_quantity_on_hand)
         FROM inventory inv2
         WHERE inv2.inv_item_sk = i.i_item_sk
       ) AS total_inventory_for_item
   FROM store_sales ss
   JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   FULL OUTER JOIN web_sales ws
       ON ss.ss_item_sk = ws.ws_item_sk
      AND ss.ss_sold_time_sk = ws.ws_sold_time_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                         AND inv.inv_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN web_returns wr
          ON wr.wr_item_sk = i.i_item_sk
         AND wr.wr_order_number = ws.ws_order_number
         AND wr.wr_returned_time_sk = td.t_time_sk
   LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   WHERE td.t_meal_time = 'dinner'
     AND w.w_gmt_offset = -5.00
     AND i.i_brand = 'Brand#12'
     AND s.s_state = 'CA'
     AND i.i_item_sk NOT IN (SELECT ws_item_sk FROM web_sales)
),
ranked AS (
   SELECT
       *,
       ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY ss_net_profit DESC) AS rn_store_profit
   FROM base
)
SELECT
    rn_store_profit,
    ss_sold_date_sk,
    ss_sold_time_sk,
    i_item_id,
    i_brand,
    s_store_name,
    s_state,
    w_warehouse_id,
    total_inventory_for_item,
    r_reason_desc,
    inv_quantity_on_hand,
    wr_return_quantity
FROM ranked
WHERE rn_store_profit <= 10
  AND ss_store_sk NOT IN (SELECT s_store_sk FROM excluded_store_keys)
ORDER BY s_state, s_store_name, rn_store_profit
OFFSET 0
LIMIT 100
