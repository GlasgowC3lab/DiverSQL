WITH
  -- Items that have sales records
  sold_items AS (
    SELECT DISTINCT ss.ss_item_sk AS item_sk
    FROM store_sales ss
  ),

  -- Items that have web return records
  web_return_items AS (
    SELECT DISTINCT wr.wr_item_sk AS item_sk
    FROM web_returns wr
  ),

  -- Items that appear in both sales and web returns
  common_items AS (
    SELECT item_sk FROM sold_items
    INTERSECT
    SELECT item_sk FROM web_return_items
  ),

  -- All inventory items
  inventory_items AS (
    SELECT inv.inv_item_sk AS item_sk
    FROM inventory inv
  ),

  -- Inventory items that never sold (EXCEPT)
  inventory_not_sold AS (
    SELECT item_sk FROM inventory_items
    EXCEPT
    SELECT item_sk FROM sold_items
  ),

  -- Aggregate web return amounts per item
  web_return_agg AS (
    SELECT i.i_item_sk,
           SUM(wr.wr_return_amt) AS web_return_total
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
  ),

  -- Sales + catalog return aggregates per item (joined via item)
  item_sales_returns AS (
    SELECT
      i.i_item_sk,
      i.i_product_name,
      COALESCE(SUM(ss.ss_quantity), 0)               AS total_quantity_sold,
      COALESCE(SUM(cr.cr_return_amount), 0)          AS total_return_amount,
      COALESCE(SUM(ss.ss_net_paid), 0)               AS total_net_paid,
      ca.ca_state,
      hd.hd_income_band_sk,
      w.w_warehouse_name
    FROM item i
    LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY i.i_item_sk, i.i_product_name, ca.ca_state, hd.hd_income_band_sk, w.w_warehouse_name
  ),

  -- Combine the sales/return data with web‑return data using a FULL OUTER JOIN
  combined AS (
    SELECT
      COALESCE(s.i_item_sk, w.i_item_sk)                AS i_item_sk,
      s.i_product_name,
      s.total_quantity_sold,
      s.total_return_amount,
      s.total_net_paid,
      s.ca_state,
      s.hd_income_band_sk,
      s.w_warehouse_name,
      w.web_return_total
    FROM item_sales_returns s
    FULL OUTER JOIN web_return_agg w ON s.i_item_sk = w.i_item_sk
  ),

  -- Rank items within each warehouse by total return amount
  ranked_items AS (
    SELECT
      c.*, 
      RANK() OVER (PARTITION BY w_warehouse_name ORDER BY total_return_amount DESC) AS warehouse_return_rank
    FROM combined c
  )

SELECT
  r.i_item_sk,
  r.i_product_name,
  r.total_quantity_sold,
  r.total_return_amount,
  r.total_net_paid,
  r.ca_state,
  r.hd_income_band_sk,
  r.w_warehouse_name,
  r.web_return_total,
  r.warehouse_return_rank,
  rc.r_reason_desc,
  cp.cp_department,
  wp.wp_url
FROM ranked_items r

-- LATERAL sub‑query: most frequent return reason for this item (catalog returns)
LEFT JOIN LATERAL (
  SELECT reason.r_reason_desc
  FROM catalog_returns cr
  JOIN reason ON cr.cr_reason_sk = reason.r_reason_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE cr.cr_item_sk = r.i_item_sk
  ORDER BY cr.cr_return_amount DESC
  LIMIT 1
) rc ON TRUE

-- LATERAL sub‑query: department from the catalog page linked to the most valuable catalog return
LEFT JOIN LATERAL (
  SELECT cp.cp_department
  FROM catalog_returns cr
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE cr.cr_item_sk = r.i_item_sk
  ORDER BY cr.cr_return_amount DESC
  LIMIT 1
) cp ON TRUE

-- LATERAL sub‑query: URL of the web page that generated the biggest web return for this item
LEFT JOIN LATERAL (
  SELECT wp.wp_url
  FROM web_returns wr
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE wr.wr_item_sk = r.i_item_sk
  ORDER BY wr.wr_return_amt DESC
  LIMIT 1
) wp ON TRUE

WHERE r.total_quantity_sold > 100
  AND r.total_return_amount > 500
  AND r.w_warehouse_name IS NOT NULL
ORDER BY r.total_return_amount DESC, r.i_item_sk
LIMIT 100
