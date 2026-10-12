WITH
  -- Aggregate store sales (right join keeps all dates) and filter by promotions
  sales_agg AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      i.i_item_id,
      SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    RIGHT OUTER JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_item_sk = ss.ss_item_sk
            AND p.p_start_date_sk = d.d_date_sk
        )
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY ROLLUP (d.d_year, d.d_month_seq, i.i_item_id)
  ),

  -- Aggregate inventory on the same dimensions
  inventory_agg AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      i.i_item_id,
      SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY ROLLUP (d.d_year, d.d_month_seq, i.i_item_id)
  ),

  -- Items sold in 2001
  sold_items AS (
    SELECT DISTINCT i.i_item_id
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),

  -- Items returned in 2001
  returned_items AS (
    SELECT DISTINCT i.i_item_id
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),

  -- Items sold but not returned (EXCEPT)
  sold_not_returned AS (
    SELECT i_item_id FROM sold_items
    EXCEPT
    SELECT i_item_id FROM returned_items
  ),

  -- Union of sales and inventory aggregates (deduplicated by UNION)
  combined AS (
    SELECT
      d_year,
      d_month_seq,
      i_item_id,
      'sales'      AS metric_type,
      total_sales  AS metric_value
    FROM sales_agg
    WHERE total_sales IS NOT NULL
    UNION
    SELECT
      d_year,
      d_month_seq,
      i_item_id,
      'inventory' AS metric_type,
      total_inventory AS metric_value
    FROM inventory_agg
    WHERE total_inventory IS NOT NULL
  )
SELECT
  c.d_year,
  c.d_month_seq,
  c.i_item_id,
  c.metric_type,
  c.metric_value
FROM combined c
WHERE EXISTS (
        SELECT 1
        FROM sold_not_returned snr
        WHERE snr.i_item_id = c.i_item_id
      )
ORDER BY c.d_year NULLS LAST,
         c.d_month_seq NULLS LAST,
         c.i_item_id,
         c.metric_type
LIMIT 100
