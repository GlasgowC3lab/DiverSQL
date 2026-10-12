SELECT
    inv.inv_date_sk,
    inv.inv_item_sk,
    i.i_item_id,
    CASE
        WHEN i.i_current_price > i.i_wholesale_cost THEN 'Profit'
        ELSE 'Loss'
    END AS price_vs_cost,
    inv.inv_quantity_on_hand * i.i_current_price AS inventory_value,
    i.i_current_price - i.i_wholesale_cost AS gross_margin,
    CASE
        WHEN inv.inv_quantity_on_hand = 0 THEN 'Out of Stock'
        WHEN inv.inv_quantity_on_hand < 10 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status
FROM inventory AS inv
JOIN item AS i
    ON inv.inv_item_sk = i.i_item_sk
WHERE inv.inv_date_sk = 2450990
  AND i.i_current_price > 2.07
