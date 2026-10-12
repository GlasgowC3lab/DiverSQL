/*
  Goal: Compute net profit and transaction metrics per item and promotion for the year 2001, comparing catalog, store, and web channels, while accounting for returns. The query demonstrates complex analytics by joining all selected TPC‑DS tables, applying selective filters, pre‑aggregating store sales, sampling web sales, intersecting order keys, using a LATERAL sub‑query, a FULL OUTER JOIN, and paging the final result.
*/
WITH
  /* Pre‑aggregate store_sales */
  store_agg AS (
    SELECT
      ss.ss_item_sk,
      ss.ss_sold_date_sk,
      ss.ss_promo_sk,
      SUM(ss.ss_net_profit)     AS store_net_profit,
      COUNT(*)                  AS store_txn_cnt
    FROM store_sales ss
    GROUP BY ss.ss_item_sk, ss.ss_sold_date_sk, ss.ss_promo_sk
  ),

  /* Sample a fraction of web_sales */
  sampled_web AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)   -- approx. 10 % of rows
  ),

  /* Orders that appear in both catalog_sales and the sampled web_sales */
  order_intersect AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    INTERSECT
    SELECT ws.ws_order_number AS order_number
    FROM sampled_web ws
  )

SELECT
  d_year.d_year,
  i.i_item_id,
  p.p_promo_name,
  p.p_channel_event,
  agg.store_net_profit,
  agg.store_txn_cnt,
  ws.ws_net_profit,
  ws.ws_quantity,
  cs.cs_net_profit,
  cs.cs_quantity,
  wr.wr_return_quantity,
  wr.wr_net_loss,
  lat.avg_discount
FROM catalog_sales cs
JOIN date_dim d_year               ON cs.cs_sold_date_sk = d_year.d_date_sk
JOIN time_dim t_time               ON cs.cs_sold_time_sk = t_time.t_time_sk
JOIN item i                        ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p                   ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm                  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w                   ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc                ON cs.cs_call_center_sk = cc.cc_call_center_sk
FULL OUTER JOIN store_agg agg      ON cs.cs_item_sk = agg.ss_item_sk
                                    AND cs.cs_sold_date_sk = agg.ss_sold_date_sk
                                    AND cs.cs_promo_sk = agg.ss_promo_sk
JOIN sampled_web ws                ON cs.cs_order_number = ws.ws_order_number
JOIN date_dim d_ws_sold            ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN time_dim t_ws_time            ON ws.ws_sold_time_sk = t_ws_time.t_time_sk
JOIN ship_mode sm_ws               ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws                ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN promotion p_ws                ON ws.ws_promo_sk = p_ws.p_promo_sk
LEFT JOIN web_returns wr          ON ws.ws_order_number = wr.wr_order_number
                                    AND ws.ws_item_sk = wr.wr_item_sk
JOIN order_intersect oi            ON cs.cs_order_number = oi.order_number
CROSS JOIN LATERAL (
  SELECT AVG(cs2.cs_ext_discount_amt) AS avg_discount
  FROM catalog_sales cs2
  WHERE cs2.cs_promo_sk = p.p_promo_sk
) AS lat
WHERE d_year.d_year = 2001
  AND i.i_brand = 'Brand#21'
  AND p.p_channel_event = 'N'
  AND sm.sm_type = 'AIR'
  AND w.w_state = 'CA'
ORDER BY agg.store_net_profit DESC, ws.ws_net_profit DESC
OFFSET 0
LIMIT 100
