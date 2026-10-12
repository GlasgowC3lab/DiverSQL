WITH sales_agg AS (
    SELECT
        cs_item_sk,
        SUM(cs_net_profit) AS total_profit,
        SUM(cs_quantity) AS total_quantity,
        COUNT(*) AS sales_cnt
    FROM tpcds.catalog_sales
    WHERE cs_net_paid_inc_ship > 1000
      AND cs_quantity BETWEEN 1 AND 100
      AND cs_ship_addr_sk IN (3319971, 936930)
    GROUP BY cs_item_sk
),
inventory_agg AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS on_hand_qty
    FROM tpcds.inventory
    WHERE inv_warehouse_sk IN (13, 9, 15)
      AND inv_date_sk > 2450800
    GROUP BY inv_item_sk
)
SELECT
    i.i_category,
    i.i_manager_id,
    s.total_profit,
    s.total_quantity,
    inv.on_hand_qty,
    LAG(s.total_profit) OVER (PARTITION BY i.i_category ORDER BY i.i_category) AS prev_category_profit,
    SUM(s.total_profit) OVER (PARTITION BY i.i_category ORDER BY i.i_category ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_category_profit
FROM sales_agg s
JOIN tpcds.item i
    ON s.cs_item_sk = i.i_item_sk
JOIN inventory_agg inv
    ON i.i_item_sk = inv.inv_item_sk
WHERE i.i_formulation LIKE '%steel%'
  AND i.i_manager_id IN (4, 6, 18)
ORDER BY i.i_category, s.total_profit DESC
LIMIT 100
