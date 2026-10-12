WITH
  union_set AS (
    SELECT
      d_ret.d_year AS return_year,
      d_sold.d_year AS sold_year,
      s.s_store_name,
      i.i_item_id,
      i.i_item_sk AS item_sk,
      ws.ws_quantity,
      ws.ws_ext_sales_price,
      ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY ws.ws_ext_sales_price DESC) AS rn,
      CASE
        WHEN ws.ws_quantity > (SELECT MAX(inv_quantity_on_hand) FROM inventory) THEN 'HIGH'
        ELSE 'NORMAL'
      END AS quantity_flag
    FROM date_dim d_ret
    JOIN store_returns sr ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN inventory inv ON inv.inv_date_sk = d_ret.d_date_sk AND inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    RIGHT OUTER JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE d_ret.d_year = 2000
      AND d_sold.d_year = 2000
      AND w.w_warehouse_sq_ft > 400000
      AND i.i_brand_id IN (101, 102)
      AND s.s_state = 'CA'
      AND ws.ws_quantity >= 5
      AND wsit.web_state = 'NY'
    UNION
    SELECT
      d_ret.d_year AS return_year,
      d_sold.d_year AS sold_year,
      s.s_store_name,
      i.i_item_id,
      i.i_item_sk AS item_sk,
      ws.ws_quantity,
      ws.ws_ext_sales_price,
      ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY ws.ws_ext_sales_price DESC) AS rn,
      CASE
        WHEN ws.ws_quantity > (SELECT MAX(inv_quantity_on_hand) FROM inventory) THEN 'HIGH'
        ELSE 'NORMAL'
      END AS quantity_flag
    FROM date_dim d_ret
    JOIN store_returns sr ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN inventory inv ON inv.inv_date_sk = d_ret.d_date_sk AND inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    RIGHT OUTER JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE d_ret.d_year = 2001
      AND d_sold.d_year = 2001
      AND w.w_warehouse_sq_ft > 300000
      AND i.i_brand_id IN (103, 104)
      AND s.s_state = 'TX'
      AND ws.ws_quantity >= 10
      AND wsit.web_state = 'CA'
  ),
  intersect_items AS (
    SELECT inv.inv_item_sk AS item_sk
    FROM inventory inv
    WHERE inv.inv_quantity_on_hand > 5000
    INTERSECT
    SELECT sr.sr_item_sk
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 2
  )
SELECT
  us.return_year,
  us.sold_year,
  us.s_store_name,
  us.i_item_id,
  us.ws_quantity,
  us.ws_ext_sales_price,
  us.rn,
  us.quantity_flag
FROM union_set us
JOIN intersect_items ii ON us.item_sk = ii.item_sk
ORDER BY us.return_year DESC, us.ws_ext_sales_price DESC
LIMIT 100
