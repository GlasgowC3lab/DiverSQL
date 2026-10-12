WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_warehouse_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_amt_inc_tax,
        cr.cr_refunded_cash
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 100
      AND cr.cr_refunded_cash > 5
      AND cr.cr_return_quantity >= 1
),
item_subset AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_current_price,
        i.i_container,
        i.i_product_name
    FROM item i
    WHERE i.i_container = 'Unknown'
      AND i.i_current_price BETWEEN 10 AND 1000
      AND i.i_product_name IS NOT NULL
),
warehouse_subset AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_state,
        w.w_city,
        w.w_gmt_offset
    FROM warehouse w
    WHERE w.w_state = 'CA'
      AND w.w_city LIKE '%San%'
      AND w.w_gmt_offset >= -8
),
inventory_sample AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand
    FROM inventory inv
    TABLESAMPLE BERNOULLI (10)
    WHERE inv.inv_quantity_on_hand > 0
),
joined_data AS (
    SELECT
        fr.cr_returned_date_sk,
        fr.cr_return_quantity,
        fr.cr_return_amount,
        fr.cr_return_amt_inc_tax,
        fr.cr_refunded_cash,
        i.i_item_id,
        i.i_current_price,
        w.w_warehouse_id,
        w.w_city,
        inv.inv_quantity_on_hand
    FROM filtered_returns fr
    JOIN item_subset i ON fr.cr_item_sk = i.i_item_sk
    JOIN warehouse_subset w ON fr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory_sample inv ON inv.inv_item_sk = i.i_item_sk
                               AND inv.inv_warehouse_sk = w.w_warehouse_sk
),
agg_by_warehouse AS (
    SELECT
        w_warehouse_id,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_qty,
        AVG(cr_return_amt_inc_tax) AS avg_return_inc_tax,
        COUNT(*) AS cnt_returns
    FROM joined_data
    GROUP BY w_warehouse_id
),
warehouse_ids_high_return AS (
    SELECT w_warehouse_id
    FROM agg_by_warehouse
    WHERE total_return_amount > 10000
),
warehouse_ids_many_returns AS (
    SELECT w_warehouse_id
    FROM agg_by_warehouse
    WHERE cnt_returns > 50
),
intersected_warehouses AS (
    SELECT w_warehouse_id FROM warehouse_ids_high_return
    INTERSECT
    SELECT w_warehouse_id FROM warehouse_ids_many_returns
),
unioned_agg AS (
    SELECT w_warehouse_id, total_return_amount, total_return_qty
    FROM agg_by_warehouse
    WHERE total_return_qty > 100
    UNION
    SELECT w_warehouse_id, total_return_amount, total_return_qty
    FROM agg_by_warehouse
    WHERE avg_return_inc_tax < 200
),
final_result AS (
    SELECT
        u.w_warehouse_id,
        u.total_return_amount,
        u.total_return_qty,
        ROW_NUMBER() OVER (ORDER BY u.total_return_amount DESC) AS rn
    FROM unioned_agg u
    JOIN intersected_warehouses iw ON u.w_warehouse_id = iw.w_warehouse_id
)
SELECT
    w_warehouse_id,
    total_return_amount,
    total_return_qty,
    rn
FROM final_result
ORDER BY rn
LIMIT 100
