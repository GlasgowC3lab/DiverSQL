WITH returns_agg AS (
   SELECT cr_item_sk,
          cr_returned_time_sk,
          SUM(cr_return_amount) AS total_return_amount
   FROM catalog_returns
   WHERE cr_return_amount > 0
   GROUP BY cr_item_sk, cr_returned_time_sk
),
inventory_agg AS (
   SELECT inv_item_sk,
          AVG(inv_quantity_on_hand) AS avg_inventory_qty
   FROM inventory
   GROUP BY inv_item_sk
)
SELECT
   s.s_store_name,
   i.i_class,
   SUM(ss.ss_net_profit) AS total_sales_profit,
   COALESCE(SUM(r.total_return_amount), 0) AS total_returns,
   SUM(ss.ss_net_profit) - COALESCE(SUM(r.total_return_amount), 0) AS net_profit,
   AVG(ia.avg_inventory_qty) AS avg_inventory_qty,
   RANK() OVER (PARTITION BY i.i_class ORDER BY (SUM(ss.ss_net_profit) - COALESCE(SUM(r.total_return_amount), 0)) DESC) AS store_rank_in_class
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
LEFT JOIN returns_agg r ON ss.ss_item_sk = r.cr_item_sk AND ss.ss_sold_time_sk = r.cr_returned_time_sk
LEFT JOIN inventory_agg ia ON ss.ss_item_sk = ia.inv_item_sk
WHERE ss.ss_sold_date_sk BETWEEN 2450900 AND 2451000
  AND i.i_brand_id = 123
GROUP BY s.s_store_name, i.i_class
HAVING (SUM(ss.ss_net_profit) - COALESCE(SUM(r.total_return_amount), 0)) > 1000
ORDER BY i.i_class, net_profit DESC
LIMIT 100
