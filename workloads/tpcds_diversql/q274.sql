WITH joined_data AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_item_sk,
        cr.cr_warehouse_sk,
        cr.cr_ship_mode_sk,
        cr.cr_reason_sk,
        i.i_item_id,
        i.i_current_price,
        i.i_product_name,
        cp.cp_department,
        cp.cp_catalog_number,
        sm.sm_code,
        sm.sm_carrier,
        w.w_warehouse_name,
        w.w_state,
        r.r_reason_desc,
        inv.inv_quantity_on_hand,
        cd_ref.cd_purchase_estimate,
        hd_ref.hd_income_band_sk,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_ticket_number,
        -- correlated scalar subquery: count of inventory rows for the same item
        (SELECT COUNT(*) FROM inventory inv2 WHERE inv2.inv_item_sk = i.i_item_sk) AS inventory_cnt,
        ARRAY[inv.inv_quantity_on_hand, inv.inv_quantity_on_hand * 2] AS qty_array
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = cr.cr_item_sk
    WHERE inv.inv_quantity_on_hand > 100
      AND i.i_current_price BETWEEN 20 AND 200
      AND sm.sm_code IN ('AIR', 'SEA')
      AND cd_ref.cd_purchase_estimate >= 3000
      AND w.w_state = 'CA'
      AND cp.cp_department = 'Electronics'
      AND NOT EXISTS (
          SELECT 1 FROM store_returns sr2
          WHERE sr2.sr_item_sk = cr.cr_item_sk
            AND sr2.sr_return_amt > 500
      )
),
expanded AS (
    SELECT
        jd.*, 
        qty_val,
        COALESCE(jd.cr_return_amount, 0) + COALESCE(jd.sr_return_amt, 0) AS total_return_amount
    FROM joined_data jd
    CROSS JOIN UNNEST(jd.qty_array) AS t(qty_val)
)
SELECT
    ed.cr_returned_date_sk,
    ed.i_item_id,
    ed.i_product_name,
    ed.cp_department,
    ed.w_warehouse_name,
    ed.sm_code,
    ed.r_reason_desc,
    ed.inv_quantity_on_hand,
    ed.inventory_cnt,
    ed.qty_val,
    ed.total_return_amount,
    RANK() OVER (PARTITION BY ed.i_item_id ORDER BY ed.total_return_amount DESC) AS return_rank
FROM expanded ed
ORDER BY return_rank
LIMIT 100
