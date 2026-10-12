WITH
  base AS (
    SELECT
      d.d_year,
      sm.sm_ship_mode_id,
      ws.ws_order_number,
      ws.ws_net_profit,
      cr.cr_return_amount,
      wr.wr_return_amt,
      inv.inv_quantity_on_hand,
      ARRAY[sm.sm_ship_mode_sk, ws.ws_warehouse_sk] AS mode_wh_arr
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    FULL OUTER JOIN tpcds.inventory inv ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN tpcds.web_sales ws ON ws.ws_ship_date_sk = d.d_date_sk
    LEFT JOIN tpcds.web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN tpcds.web_returns wr ON wr.wr_order_number = ws.ws_order_number
                                   AND wr.wr_item_sk = ws.ws_item_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND inv.inv_quantity_on_hand > 0
      AND cr.cr_return_quantity > 5
      AND ws.ws_quantity >= 2
      AND wsite.web_country = 'United States'
  ),
  unnested AS (
    SELECT
      b.d_year,
      b.sm_ship_mode_id,
      b.ws_order_number,
      b.ws_net_profit,
      b.cr_return_amount,
      b.wr_return_amt,
      b.inv_quantity_on_hand,
      t.mode_warehouse_sk
    FROM base b
    CROSS JOIN UNNEST(b.mode_wh_arr) AS t(mode_warehouse_sk)
  ),
  order_diff AS (
    SELECT ws_order_number FROM tpcds.web_sales WHERE ws_quantity > 10
    EXCEPT
    SELECT cr_order_number FROM tpcds.catalog_returns WHERE cr_return_quantity > 50
  ),
  agg_year_2001 AS (
    SELECT
      sm_ship_mode_id,
      d_year,
      SUM(ws_net_profit) AS total_net_profit,
      SUM(cr_return_amount) AS total_catalog_return,
      SUM(wr_return_amt) AS total_web_return,
      AVG(inv_quantity_on_hand) AS avg_inventory,
      COUNT(DISTINCT ws_order_number) AS distinct_orders
    FROM unnested
    WHERE ws_order_number NOT IN (SELECT ws_order_number FROM order_diff)
    GROUP BY CUBE(sm_ship_mode_id, d_year)
    HAVING d_year = 2001
  ),
  agg_year_2002 AS (
    SELECT
      sm_ship_mode_id,
      d_year,
      SUM(ws_net_profit) AS total_net_profit,
      SUM(cr_return_amount) AS total_catalog_return,
      SUM(wr_return_amt) AS total_web_return,
      AVG(inv_quantity_on_hand) AS avg_inventory,
      COUNT(DISTINCT ws_order_number) AS distinct_orders
    FROM unnested
    WHERE ws_order_number NOT IN (SELECT ws_order_number FROM order_diff)
    GROUP BY CUBE(sm_ship_mode_id, d_year)
    HAVING d_year = 2002
  )
SELECT *
FROM (
  SELECT * FROM agg_year_2001
  UNION
  SELECT * FROM agg_year_2002
) combined
ORDER BY sm_ship_mode_id, d_year
LIMIT 100
