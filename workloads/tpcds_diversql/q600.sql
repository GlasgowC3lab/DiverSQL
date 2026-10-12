WITH
  full_store_warehouse AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      s.s_state AS store_state,
      w.w_warehouse_sk,
      w.w_warehouse_name,
      w.w_state AS warehouse_state
    FROM store s
    FULL OUTER JOIN warehouse w
      ON s.s_state = w.w_state
  ),
  recent_sales AS (
    SELECT
      ws.ws_order_number,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ws.ws_ext_sales_price > 100
  ),
  shipped_sales AS (
    SELECT
      ws.ws_order_number,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_ship_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ws.ws_ext_sales_price > 100
  ),
  intersect_orders AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    JOIN date_dim d1 ON ws.ws_sold_date_sk = d1.d_date_sk
    WHERE d1.d_year = 2001
    INTERSECT
    SELECT ws.ws_order_number
    FROM web_sales ws
    JOIN date_dim d2 ON ws.ws_ship_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
  ),
  anti_orders AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_order_number NOT IN (
      SELECT ws2.ws_order_number
      FROM web_sales ws2
      WHERE ws2.ws_ext_tax > 50
    )
  )
SELECT
  final.order_num,
  final.sales_price,
  final.profit_flag,
  final.store_name,
  final.warehouse_name
FROM (
  SELECT
    rs.ws_order_number      AS order_num,
    rs.ws_ext_sales_price   AS sales_price,
    rs.profit_flag,
    CAST(NULL AS varchar)   AS store_name,
    CAST(NULL AS varchar)   AS warehouse_name
  FROM recent_sales rs

  UNION ALL

  SELECT
    ss.ws_order_number,
    ss.ws_ext_sales_price,
    ss.profit_flag,
    CAST(NULL AS varchar),
    CAST(NULL AS varchar)
  FROM shipped_sales ss

  UNION ALL

  SELECT
    CAST(NULL AS integer)           AS order_num,
    CAST(NULL AS decimal(7,2))      AS sales_price,
    CAST(NULL AS varchar)           AS profit_flag,
    fw.s_store_name                 AS store_name,
    fw.w_warehouse_name             AS warehouse_name
  FROM full_store_warehouse fw
) AS final
WHERE final.order_num IS NOT NULL
  AND final.order_num IN (SELECT ws_order_number FROM intersect_orders)
  AND final.order_num IN (SELECT ws_order_number FROM anti_orders)
ORDER BY final.sales_price DESC
LIMIT 100
