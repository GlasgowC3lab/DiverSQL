WITH distinct_items AS (
    SELECT DISTINCT
        i_item_sk,
        i_item_id,
        i_product_name,
        i_brand_id,
        i_units,
        i_size
    FROM item
    WHERE i_brand_id = 1001001
),
inventory_agg AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_item_sk
)
SELECT
    di.i_item_id,
    td.t_sub_shift,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid_inc_ship_tax,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
    MIN(cs.cs_ext_list_price) AS min_list_price,
    MAX(cs.cs_ext_list_price) AS max_list_price,
    inv_agg.total_qty_on_hand,
    CASE
        WHEN SUM(cs.cs_net_paid_inc_ship_tax) > 500000 THEN 'High'
        WHEN SUM(cs.cs_net_paid_inc_ship_tax) BETWEEN 100000 AND 500000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_tier
FROM catalog_sales cs
JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
JOIN distinct_items di
    ON cs.cs_item_sk = di.i_item_sk
JOIN inventory_agg inv_agg
    ON di.i_item_sk = inv_agg.inv_item_sk
WHERE
    td.t_sub_shift = 'morning'
    AND cs.cs_ext_list_price > 3000
    AND td.t_second IN (12, 16, 19)
GROUP BY
    di.i_item_id,
    td.t_sub_shift,
    inv_agg.total_qty_on_hand
ORDER BY total_net_paid_inc_ship_tax DESC
LIMIT 100
