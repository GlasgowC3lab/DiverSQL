WITH high_return_catalog AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cp.cp_department,
        w.w_warehouse_id,
        t.t_hour,
        CASE WHEN cr.cr_return_amount > 100 THEN 'High' ELSE 'Low' END AS amount_category
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE cp.cp_department = 'DEPARTMENT'
      AND w.w_zip = '74136'
)
SELECT *
FROM (
    SELECT
        cr_order_number AS order_number,
        'catalog' AS source,
        amount_category,
        cr_return_amount,
        cr_return_amount - (SELECT avg(cr_return_amount) FROM catalog_returns) AS amount_vs_avg,
        cr_return_quantity,
        cp_department,
        w_warehouse_id,
        t_hour
    FROM high_return_catalog
    WHERE w_warehouse_id NOT IN (
        SELECT w_warehouse_id FROM warehouse WHERE w_gmt_offset = -5.00
    )

    UNION ALL

    SELECT
        wr.wr_order_number AS order_number,
        'web' AS source,
        CASE WHEN wr.wr_return_amt > 100 THEN 'High' ELSE 'Low' END AS amount_category,
        wr.wr_return_amt AS cr_return_amount,
        wr.wr_return_amt - (SELECT avg(wr_return_amt) FROM web_returns) AS amount_vs_avg,
        wr.wr_return_quantity AS cr_return_quantity,
        wp.wp_type AS cp_department,
        w.w_warehouse_id,
        t.t_hour
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE wp.wp_type = 'Content'
      AND w.w_zip = '74136'
      AND w.w_warehouse_id NOT IN (
          SELECT w_warehouse_id FROM warehouse WHERE w_gmt_offset = -5.00
      )
) combined
ORDER BY order_number DESC
LIMIT 100
