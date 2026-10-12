WITH warehouse_inventory AS (
  SELECT inv_warehouse_sk,
         COUNT(DISTINCT inv_item_sk) AS distinct_items,
         SUM(inv_quantity_on_hand) AS total_qty,
         AVG(inv_quantity_on_hand) AS avg_qty,
         MAX(inv_quantity_on_hand) AS max_qty,
         MIN(inv_quantity_on_hand) AS min_qty
  FROM inventory
  WHERE inv_date_sk BETWEEN 2450900 AND 2451053
  GROUP BY inv_warehouse_sk
  HAVING SUM(inv_quantity_on_hand) > 2000
),
warehouse_rank AS (
  SELECT wi.*, ROW_NUMBER() OVER (ORDER BY wi.total_qty DESC) AS rank_total_qty
  FROM warehouse_inventory wi
)
SELECT ws.web_site_id,
       ws.web_name,
       ws.web_state,
       wr.inv_warehouse_sk,
       wr.distinct_items,
       wr.total_qty,
       wr.avg_qty,
       wr.max_qty,
       wr.min_qty,
       wr.rank_total_qty
FROM warehouse_rank wr
JOIN web_site ws ON ws.web_company_id = wr.inv_warehouse_sk
WHERE ws.web_tax_percentage < 5.00
ORDER BY wr.total_qty DESC
LIMIT 20
