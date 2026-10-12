WITH
  inv_full AS (
    SELECT
      i.inv_item_sk,
      i.inv_quantity_on_hand,
      it.i_item_id,
      it.i_current_price,
      it.i_brand,
      it.i_category
    FROM inventory i
    FULL OUTER JOIN item it
      ON i.inv_item_sk = it.i_item_sk
  ),
  web_agg AS (
    SELECT
      ws.ws_item_sk   AS item_sk,
      ws.ws_ship_mode_sk AS ship_mode_sk,
      ws.ws_web_site_sk  AS web_site_sk,
      SUM(ws.ws_quantity)          AS total_ws_qty,
      SUM(ws.ws_net_paid)          AS total_ws_net_paid
    FROM web_sales ws
    WHERE ws.ws_quantity > 0
      AND ws.ws_sold_date_sk BETWEEN 2450815 AND 2450900
    GROUP BY ws.ws_item_sk, ws.ws_ship_mode_sk, ws.ws_web_site_sk
  ),
  store_ret_agg AS (
    SELECT
      sr.sr_item_sk AS item_sk,
      sr.sr_store_sk AS store_sk,
      COUNT(*)                     AS return_cnt,
      SUM(sr.sr_return_amt)        AS total_return_amt
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
      AND sr.sr_returned_date_sk BETWEEN 2450815 AND 2450900
    GROUP BY sr.sr_item_sk, sr.sr_store_sk
  ),
  branch_a AS (
    SELECT
      it.i_item_id                     AS item_id,
      sm.sm_type                       AS descriptor,
      ws_agg.total_ws_qty              AS metric_qty,
      ws_agg.total_ws_net_paid         AS metric_amount,
      'web'                            AS source
    FROM web_agg ws_agg
    JOIN item it          ON ws_agg.item_sk = it.i_item_sk
    JOIN ship_mode sm     ON ws_agg.ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsit    ON ws_agg.web_site_sk = wsit.web_site_sk
    WHERE sm.sm_contract = 'I3uCelXtjP'
  ),
  branch_b AS (
    SELECT
      it.i_item_id                     AS item_id,
      st.s_city                        AS descriptor,
      sr_agg.return_cnt                AS metric_qty,
      sr_agg.total_return_amt          AS metric_amount,
      'store'                          AS source
    FROM store_ret_agg sr_agg
    JOIN item it          ON sr_agg.item_sk = it.i_item_sk
    JOIN store st        ON sr_agg.store_sk = st.s_store_sk
    WHERE st.s_state = 'CA'
  ),
  union_data AS (
    SELECT DISTINCT * FROM branch_a
    UNION DISTINCT
    SELECT DISTINCT * FROM branch_b
  ),
  filtered_items AS (
    SELECT *
    FROM union_data ud
    WHERE ud.item_id IN (
      SELECT i2.i_item_id
      FROM item i2
      WHERE i2.i_wholesale_cost > 20
    )
  )
SELECT
  fi.item_id,
  fi.descriptor,
  SUM(fi.metric_qty)          AS total_quantity,
  AVG(fi.metric_amount)      AS avg_amount,
  CASE WHEN fi.source = 'web' THEN 'Online' ELSE 'In-Store' END AS channel,
  COUNT(DISTINCT fi.source)   AS source_count
FROM filtered_items fi
LEFT JOIN inv_full inv
  ON inv.i_item_id = fi.item_id
WHERE inv.inv_quantity_on_hand IS NULL OR inv.inv_quantity_on_hand > 10
GROUP BY
  fi.item_id,
  fi.descriptor,
  fi.source
ORDER BY total_quantity DESC, avg_amount DESC
LIMIT 100
