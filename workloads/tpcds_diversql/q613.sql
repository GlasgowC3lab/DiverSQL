WITH recent_items AS (
    SELECT
        i_item_sk,
        i_item_id,
        i_product_name,
        i_category,
        i_brand,
        i_brand_id,
        i_current_price,
        i_units,
        i_rec_start_date,
        i_rec_end_date,
        i_color,
        i_formulation
    FROM item
    WHERE i_rec_start_date <= DATE '2001-01-01'
      AND i_rec_end_date   >= DATE '2000-12-31'
      AND i_units IN ('Each', 'Cup', 'Pallet')
      AND i_brand_id BETWEEN 1 AND 5
      AND i_formulation = 'Standard'
),
filtered_inventory AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        inv_quantity_on_hand,
        inv_date_sk
    FROM inventory
    WHERE inv_quantity_on_hand > 50
      AND inv_warehouse_sk IN (8, 9, 10)
      AND inv_date_sk BETWEEN 2450900 AND 2451100
),
intersected_items AS (
    SELECT inv_item_sk FROM filtered_inventory
    INTERSECT
    SELECT i_item_sk FROM recent_items
),
dim_levels AS (
    SELECT level FROM (VALUES 'Low', 'Medium', 'High') AS t(level)
),
category_levels AS (
    SELECT DISTINCT i_category FROM recent_items
)
SELECT
    ri.i_item_id,
    ri.i_product_name,
    fi.inv_warehouse_sk,
    fi.inv_quantity_on_hand,
    ri.i_current_price,
    ri.i_units,
    ROW_NUMBER() OVER (PARTITION BY ri.i_category ORDER BY fi.inv_quantity_on_hand DESC) AS category_rank,
    dl.level AS quantity_level,
    cl.i_category AS category_name
FROM intersected_items ii
JOIN recent_items ri ON ii.inv_item_sk = ri.i_item_sk
JOIN filtered_inventory fi ON ri.i_item_sk = fi.inv_item_sk
CROSS JOIN dim_levels dl
CROSS JOIN category_levels cl
WHERE ri.i_current_price > (SELECT AVG(i_current_price) FROM item)
  AND ri.i_units IN ('Each', 'Cup', 'Pallet')
  AND ri.i_brand_id = 3
  AND fi.inv_quantity_on_hand > 70
  AND fi.inv_warehouse_sk = 9
  AND ri.i_rec_start_date <= DATE '2001-01-01'
  AND ri.i_rec_end_date   >= DATE '2000-12-31'
ORDER BY category_rank, ri.i_current_price DESC
LIMIT 100
