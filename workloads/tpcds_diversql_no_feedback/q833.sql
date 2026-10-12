WITH agg AS (
    SELECT
        i.i_brand_id AS brand_id,
        i.i_brand AS brand,
        w.w_warehouse_name AS warehouse_name,
        w.w_state AS state,
        SUM(inv.inv_quantity_on_hand) AS total_qty,
        CASE WHEN i.i_current_price > 100 THEN 'expensive' ELSE 'regular' END AS price_category
    FROM tpcds.inventory inv
    JOIN tpcds.item i
        ON inv.inv_item_sk = i.i_item_sk
    JOIN tpcds.warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_brand_id IN (8015002, 6008007, 5003002)
      AND w.w_state = 'CA'
      AND inv.inv_quantity_on_hand > 500
      AND inv.inv_date_sk BETWEEN 2451060 AND 2451080
    GROUP BY
        i.i_brand_id,
        i.i_brand,
        w.w_warehouse_name,
        w.w_state,
        CASE WHEN i.i_current_price > 100 THEN 'expensive' ELSE 'regular' END
)
SELECT
    brand_id,
    brand,
    warehouse_name,
    state,
    total_qty,
    price_category,
    RANK() OVER (PARTITION BY brand_id ORDER BY total_qty DESC) AS warehouse_qty_rank
FROM agg
ORDER BY brand_id, warehouse_qty_rank
LIMIT 100
