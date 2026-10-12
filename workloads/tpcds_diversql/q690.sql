WITH
  -- Items whose description contains a three‑digit number and product name contains "Pro"
  item_match AS (
    SELECT
      i.i_item_sk,
      i.i_item_desc,
      i.i_product_name,
      i.i_brand,
      i.i_color,
      i.i_size
    FROM tpcds.item i
    WHERE regexp_like(i.i_item_desc, '.*[0-9]{3}.*')
      AND i.i_product_name LIKE '%Pro%'
  ),
  -- Inventory for a concrete date (example: 2002‑01‑15)
  inventory_recent AS (
    SELECT inv_item_sk
    FROM tpcds.inventory inv
    WHERE inv.inv_date_sk = (
      SELECT d.d_date_sk
      FROM tpcds.date_dim d
      WHERE d.d_date = DATE '2002-01-15'
    )
  ),
  -- Inventory items with low quantity on hand
  inventory_low_qty AS (
    SELECT inv_item_sk
    FROM tpcds.inventory inv
    WHERE inv.inv_quantity_on_hand < 100
  ),
  -- Inventory located in warehouse 1 (arbitrary example)
  inventory_warehouse_one AS (
    SELECT inv_item_sk
    FROM tpcds.inventory inv
    WHERE inv.inv_warehouse_sk = 1
  ),
  -- Items that survive the set operations (EXCEPT then INTERSECT)
  eligible_items AS (
    SELECT im.i_item_sk,
           im.i_item_desc,
           im.i_product_name,
           im.i_brand,
           im.i_color,
           im.i_size
    FROM item_match im
    WHERE im.i_item_sk IN (
      (
        SELECT inv_item_sk FROM inventory_recent
        EXCEPT
        SELECT inv_item_sk FROM inventory_low_qty
      )
      INTERSECT
      SELECT inv_item_sk FROM inventory_warehouse_one
    )
  ),
  -- Aggregate web sales for the eligible items
  sales_agg AS (
    SELECT
      ei.i_item_sk,
      d.d_date,
      COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
      SUM(DISTINCT ws.ws_ext_sales_price) AS distinct_sales_sum,
      SUM(ws.ws_net_profit) AS total_net_profit
    FROM eligible_items ei
    JOIN tpcds.web_sales ws ON ws.ws_item_sk = ei.i_item_sk
    JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE ws.ws_ext_sales_price > 0
    GROUP BY ei.i_item_sk, d.d_date
  ),
  -- Add window functions
  final AS (
    SELECT
      s.i_item_sk,
      s.d_date,
      s.unique_customers,
      s.distinct_sales_sum,
      s.total_net_profit,
      LAG(s.total_net_profit) OVER (PARTITION BY s.i_item_sk ORDER BY s.d_date) AS prev_net_profit,
      ROW_NUMBER() OVER (PARTITION BY s.i_item_sk ORDER BY s.d_date) AS day_seq
    FROM sales_agg s
  )
SELECT
  f.i_item_sk,
  f.d_date,
  f.unique_customers,
  f.distinct_sales_sum,
  f.total_net_profit,
  f.prev_net_profit,
  f.day_seq,
  CONCAT(CAST(f.i_item_sk AS VARCHAR), '-', CAST(f.day_seq AS VARCHAR)) AS item_day_key
FROM final f
ORDER BY f.total_net_profit DESC
LIMIT 100
