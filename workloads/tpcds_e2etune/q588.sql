WITH inventory_summary AS (
  SELECT
    inv_item_sk,
    inv_warehouse_sk,
    AVG(inv_quantity_on_hand) AS avg_qty_on_hand,
    MAX(inv_date_sk) AS latest_inv_date
  FROM inventory
  WHERE inv_date_sk >= (
    SELECT MAX(inv_date_sk) - 30 FROM inventory
  )
  GROUP BY inv_item_sk, inv_warehouse_sk
),
sales_agg AS (
  SELECT
    cs.cs_item_sk,
    cs.cs_warehouse_sk,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    AVG(cs.cs_ext_sales_price) AS avg_sales_price,
    SUM(cs.cs_quantity) AS total_quantity
  FROM catalog_sales cs
  WHERE cs.cs_ext_sales_price > 1000
    AND cs.cs_ext_tax > 0
    AND cs.cs_catalog_page_sk IN (159, 23, 244)
    AND cs.cs_sold_date_sk BETWEEN (
      SELECT MAX(cs_sold_date_sk) - 90 FROM catalog_sales
    ) AND (
      SELECT MAX(cs_sold_date_sk) FROM catalog_sales
    )
  GROUP BY cs.cs_item_sk, cs.cs_warehouse_sk
)
SELECT
  s.cs_item_sk AS item_sk,
  s.cs_warehouse_sk AS warehouse_sk,
  s.total_net_paid,
  s.total_net_profit,
  s.order_cnt,
  s.avg_sales_price,
  s.total_quantity,
  i.avg_qty_on_hand,
  i.latest_inv_date,
  RANK() OVER (ORDER BY s.total_net_profit DESC) AS profit_rank
FROM sales_agg s
JOIN inventory_summary i
  ON s.cs_item_sk = i.inv_item_sk
 AND s.cs_warehouse_sk = i.inv_warehouse_sk
WHERE s.total_net_profit > 500
ORDER BY s.total_net_profit DESC
LIMIT 10
