WITH inv_agg AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    WHERE inv_quantity_on_hand > 100
    GROUP BY inv_warehouse_sk
)
SELECT
    cr_order_number,
    cc_name,
    cp_department,
    w_warehouse_name,
    t_hour,
    cr_return_amount,
    cr_return_amt_inc_tax,
    cr_refunded_cash,
    total_qty,
    dept_avg_return,
    return_amount_rank,
    overall_row_num
FROM (
    SELECT
        cr.cr_order_number,
        cc.cc_name,
        cp.cp_department,
        w.w_warehouse_name,
        t.t_hour,
        cr.cr_return_amount,
        cr.cr_return_amt_inc_tax,
        cr.cr_refunded_cash,
        inv_agg.total_qty,
        dept_stats.dept_avg_return,
        RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY cr.cr_return_amount DESC) AS return_amount_rank,
        ROW_NUMBER() OVER (ORDER BY cr.cr_return_amount DESC) AS overall_row_num
    FROM catalog_returns cr
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim t
      ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inv_agg
      ON w.w_warehouse_sk = inv_agg.inv_warehouse_sk
    CROSS JOIN LATERAL (
        SELECT AVG(cr3.cr_return_amount) AS dept_avg_return
        FROM catalog_returns cr3
        JOIN catalog_page cp3
          ON cr3.cr_catalog_page_sk = cp3.cp_catalog_page_sk
        WHERE cp3.cp_department = cp.cp_department
    ) AS dept_stats
    WHERE w.w_zip = '56098'
      AND cc.cc_state = 'CA'
      AND cr.cr_return_amount > 50
      AND cr.cr_order_number NOT IN (
          SELECT cr2.cr_order_number
          FROM catalog_returns cr2
          WHERE cr2.cr_return_amount = 0
      )
) ranked
WHERE return_amount_rank <= 3
ORDER BY w_warehouse_name, return_amount_rank
LIMIT 50
