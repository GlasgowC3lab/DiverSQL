WITH high_inventory AS (
        SELECT i.i_item_sk,
               i.i_product_name,
               SUM(inv.inv_quantity_on_hand) AS total_qty
        FROM inventory inv
        JOIN item i ON inv.inv_item_sk = i.i_item_sk
        WHERE inv.inv_warehouse_sk = 10
        GROUP BY i.i_item_sk, i.i_product_name
        HAVING SUM(inv.inv_quantity_on_hand) > 500
    ),
    promo_items AS (
        SELECT i.i_item_sk,
               i.i_product_name,
               p.p_promo_name,
               p.p_cost
        FROM promotion p
        JOIN item i ON p.p_item_sk = i.i_item_sk
        WHERE p.p_discount_active = 'Y'
          AND p.p_channel_dmail = 'Y'
    ),
    low_price_items AS (
        SELECT i.i_item_sk,
               i.i_product_name,
               i.i_current_price
        FROM item i
        WHERE i.i_current_price < 2.00
    )
SELECT s.i_item_sk,
       s.i_product_name,
       CASE WHEN EXISTS (
                SELECT 1
                FROM inventory inv2
                WHERE inv2.inv_item_sk = s.i_item_sk
                  AND inv2.inv_warehouse_sk = 9
            ) THEN 'Y' ELSE 'N' END AS has_warehouse9
FROM (
        SELECT hi.i_item_sk,
               hi.i_product_name
        FROM high_inventory hi
        JOIN promo_items pi ON hi.i_item_sk = pi.i_item_sk
        EXCEPT
        SELECT li.i_item_sk,
               li.i_product_name
        FROM low_price_items li
     ) s
LIMIT 100
