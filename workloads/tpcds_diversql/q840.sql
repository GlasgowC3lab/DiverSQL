WITH store_data AS (
   SELECT
       s.s_store_id AS channel_id,
       i.i_category,
       i.i_item_id,
       COALESCE(ss.ss_quantity, 0) AS sold_qty,
       COALESCE(sr.sr_return_quantity, 0) AS returned_qty,
       COALESCE(ss.ss_net_profit, 0) - COALESCE(sr.sr_net_loss, 0) AS net_profit,
       CASE WHEN COALESCE(ss.ss_quantity, 0) = 0 THEN 0
            ELSE (COALESCE(ss.ss_quantity, 0) - COALESCE(sr.sr_return_quantity, 0)) * 1.0 / COALESCE(ss.ss_quantity, 0)
       END AS sell_through_rate
   FROM store_sales ss
   FULL OUTER JOIN store_returns sr
       ON ss.ss_ticket_number = sr.sr_ticket_number
   LEFT JOIN store s
       ON COALESCE(ss.ss_store_sk, sr.sr_store_sk) = s.s_store_sk
   LEFT JOIN item i
       ON COALESCE(ss.ss_item_sk, sr.sr_item_sk) = i.i_item_sk
   WHERE (ss.ss_sold_date_sk BETWEEN 2450815 AND 2451179
          OR sr.sr_returned_date_sk BETWEEN 2450815 AND 2451179)
),
web_data AS (
   SELECT
       'WEB' AS channel_id,
       i.i_category,
       i.i_item_id,
       COALESCE(ws.ws_quantity, 0) AS sold_qty,
       COALESCE(wr.wr_return_quantity, 0) AS returned_qty,
       COALESCE(ws.ws_net_profit, 0) - COALESCE(wr.wr_net_loss, 0) AS net_profit,
       CASE WHEN COALESCE(ws.ws_quantity, 0) = 0 THEN 0
            ELSE (COALESCE(ws.ws_quantity, 0) - COALESCE(wr.wr_return_quantity, 0)) * 1.0 / COALESCE(ws.ws_quantity, 0)
       END AS sell_through_rate
   FROM web_sales ws
   FULL OUTER JOIN web_returns wr
       ON ws.ws_order_number = wr.wr_order_number
   LEFT JOIN item i
       ON COALESCE(ws.ws_item_sk, wr.wr_item_sk) = i.i_item_sk
   WHERE (ws.ws_sold_date_sk BETWEEN 2450815 AND 2451179
          OR wr.wr_returned_date_sk BETWEEN 2450815 AND 2451179)
),
combined AS (
   SELECT * FROM store_data
   UNION ALL
   SELECT * FROM web_data
),
agg AS (
   SELECT
       channel_id,
       i_category,
       i_item_id,
       SUM(sold_qty) AS total_sold_qty,
       SUM(returned_qty) AS total_returned_qty,
       SUM(net_profit) AS total_net_profit,
       AVG(sell_through_rate) AS avg_sell_through_rate
   FROM combined
   GROUP BY ROLLUP (channel_id, i_category, i_item_id)
),
ranked AS (
   SELECT
       *,
       ROW_NUMBER() OVER (PARTITION BY channel_id ORDER BY total_net_profit DESC) AS rnk
   FROM agg
   WHERE i_item_id IS NOT NULL
)
SELECT
   channel_id,
   i_category,
   i_item_id,
   total_sold_qty,
   total_returned_qty,
   total_net_profit,
   avg_sell_through_rate,
   rnk
FROM ranked
WHERE rnk <= 5
ORDER BY channel_id, total_net_profit DESC
OFFSET 0 LIMIT 100
