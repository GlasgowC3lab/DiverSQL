WITH
    sales_filtered AS (
        SELECT
            cs.cs_order_number,
            cs.cs_item_sk,
            cs.cs_net_profit,
            cs.cs_ext_ship_cost,
            cs.cs_quantity,
            i.i_brand,
            i.i_category,
            i.i_item_id
        FROM catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        WHERE regexp_like(i.i_brand, '^edu')
          AND i.i_category LIKE '%pack%'
    ),
    inventory_nonzero AS (
        SELECT inv_item_sk
        FROM inventory
        WHERE inv_quantity_on_hand > 0
    ),
    order_exceptions AS (
        SELECT cs_order_number
        FROM catalog_sales
        WHERE cs_ext_ship_cost > 500
        EXCEPT
        SELECT cs_order_number
        FROM catalog_sales
        WHERE cs_ext_ship_cost > 1000
    )
SELECT
    sf.cs_item_sk,
    sf.i_brand,
    sf.i_category,
    COUNT(*) AS sales_cnt,
    SUM(sf.cs_net_profit) AS total_profit,
    AVG(sf.cs_ext_ship_cost) AS avg_ship_cost,
    regexp_extract(sf.i_item_id, '(\\d+)', 1) AS item_id_number
FROM sales_filtered sf
JOIN inventory_nonzero inv ON sf.cs_item_sk = inv.inv_item_sk
WHERE sf.cs_order_number NOT IN (
        SELECT cs_order_number
        FROM catalog_sales
        WHERE cs_quantity = 0
      )
  AND sf.cs_order_number IN (SELECT cs_order_number FROM order_exceptions)
GROUP BY sf.cs_item_sk, sf.i_brand, sf.i_category, regexp_extract(sf.i_item_id, '(\\d+)', 1)
ORDER BY total_profit DESC
LIMIT 100
