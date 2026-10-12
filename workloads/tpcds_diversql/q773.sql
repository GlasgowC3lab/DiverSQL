WITH cr_base AS (
    SELECT
        cr.cr_returned_date_sk,
        d.d_date,
        d.d_year,
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        cr.cr_return_amount,
        cr.cr_order_number,
        cc.cc_name,
        cp.cp_department,
        sm.sm_type,
        w.w_warehouse_name,
        w.w_warehouse_sq_ft,
        ws.web_name,
        cc.cc_hours,
        cc.cc_suite_number,
        hd.hd_vehicle_count,
        hd.hd_dep_count
    FROM catalog_returns cr
    JOIN date_dim d               ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i                  ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc          ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp         ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w             ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_site ws             ON d.d_date_sk = ws.web_open_date_sk
    WHERE d.d_year = 2001
      AND hd.hd_vehicle_count > 0
      AND w.w_warehouse_sq_ft > 500000
),
wr_exists AS (
    SELECT DISTINCT wr.wr_item_sk
    FROM web_returns wr
    JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
),
common_orders AS (
    SELECT cr_order_number AS order_no FROM catalog_returns
    INTERSECT
    SELECT wr_order_number FROM web_returns
)
SELECT
    cr_base.cr_returned_date_sk,
    cr_base.d_date,
    cr_base.i_item_id,
    cr_base.i_category,
    cr_base.cc_name,
    cr_base.cp_department,
    cr_base.sm_type,
    cr_base.w_warehouse_name,
    cr_base.web_name,
    cr_base.cr_return_amount,
    cr_base.hd_vehicle_count,
    cr_base.hd_dep_count,
    -- correlated scalar subquery: total return amount for the same item across all catalog returns
    (SELECT SUM(cr2.cr_return_amount)
     FROM catalog_returns cr2
     WHERE cr2.cr_item_sk = cr_base.i_item_sk) AS total_item_return_amount,
    -- rank items by return amount for the given day
    RANK() OVER (PARTITION BY cr_base.d_date ORDER BY cr_base.cr_return_amount DESC) AS amount_rank,
    -- unnest example: expand two text attributes into separate rows
    unn.extra_info
FROM cr_base
LEFT JOIN LATERAL (
    SELECT x AS extra_info
    FROM UNNEST(ARRAY[cr_base.cc_hours, cr_base.cc_suite_number]) AS t(x)
) unn ON TRUE
WHERE EXISTS (
        SELECT 1 FROM wr_exists we WHERE we.wr_item_sk = cr_base.i_item_sk
    )
  AND cr_base.cr_order_number IN (SELECT order_no FROM common_orders)
ORDER BY cr_base.d_date DESC, amount_rank
OFFSET 0 FETCH NEXT 100 ROWS ONLY
