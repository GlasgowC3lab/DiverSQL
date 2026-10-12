WITH inv_agg AS (
  SELECT inv_item_sk,
         inv_date_sk,
         SUM(inv_quantity_on_hand) AS total_qty_on_hand
  FROM inventory
  GROUP BY inv_item_sk, inv_date_sk
)
SELECT s.ss_store_sk,
       s.ss_item_sk,
       s.ss_sold_date_sk,
       SUM(s.ss_net_paid) AS total_sales,
       SUM(s.ss_net_profit) AS total_profit,
       inv_agg.total_qty_on_hand,
       (SUM(s.ss_net_paid) / NULLIF(inv_agg.total_qty_on_hand, 0)) AS sales_per_inventory,
       RANK() OVER (PARTITION BY s.ss_sold_date_sk ORDER BY SUM(s.ss_net_paid) DESC) AS daily_sales_rank
FROM store_sales s
JOIN inv_agg
  ON s.ss_item_sk = inv_agg.inv_item_sk
 AND s.ss_sold_date_sk = inv_agg.inv_date_sk
WHERE s.ss_sold_date_sk BETWEEN 2450815 AND 2451195
  AND s.ss_quantity > 0
GROUP BY s.ss_store_sk,
         s.ss_item_sk,
         s.ss_sold_date_sk,
         inv_agg.total_qty_on_hand
HAVING SUM(s.ss_net_paid) > 5000
ORDER BY total_profit DESC
LIMIT 200
