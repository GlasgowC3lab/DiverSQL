WITH aggregated AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        s.s_store_id,
        s.s_store_name,
        cd_closed.d_current_month,
        cd_closed.d_year,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand,
        AVG(i.i_wholesale_cost) AS avg_wholesale_cost,
        COUNT(DISTINCT inv.inv_warehouse_sk) AS warehouse_count,
        cd_open.d_current_month AS open_month
    FROM call_center cc
    JOIN date_dim cd_closed
      ON cc.cc_closed_date_sk = cd_closed.d_date_sk
    JOIN date_dim cd_open
      ON cc.cc_open_date_sk = cd_open.d_date_sk
    JOIN inventory inv
      ON inv.inv_date_sk = cd_closed.d_date_sk
    JOIN item i
      ON inv.inv_item_sk = i.i_item_sk
    JOIN store s
      ON s.s_closed_date_sk = cd_closed.d_date_sk
    WHERE cd_closed.d_year = 2022
      AND i.i_category = 'Electronics'
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        s.s_store_id,
        s.s_store_name,
        cd_closed.d_current_month,
        cd_closed.d_year,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        cd_open.d_current_month
)
SELECT
    ag.cc_call_center_id,
    ag.cc_name,
    ag.s_store_id,
    ag.s_store_name,
    ag.d_current_month,
    ag.d_year,
    ag.i_item_id,
    ag.i_product_name,
    ag.i_category,
    ag.total_qty_on_hand,
    ag.avg_wholesale_cost,
    ag.warehouse_count,
    ag.open_month,
    RANK() OVER (PARTITION BY ag.i_category ORDER BY ag.total_qty_on_hand DESC) AS category_qty_rank
FROM aggregated ag
ORDER BY ag.total_qty_on_hand DESC
LIMIT 100
