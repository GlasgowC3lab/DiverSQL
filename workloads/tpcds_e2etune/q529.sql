SELECT
    cp.cp_type,
    sm.sm_type,
    w.w_state,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    SUM(cr.cr_net_loss) / NULLIF(SUM(cr.cr_return_amount), 0) AS loss_to_return_ratio
FROM
    catalog_returns cr
JOIN
    catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN
    ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN
    warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE
    cp.cp_type = 'monthly'
    AND cp.cp_start_date_sk BETWEEN 2450815 AND 2451088
    AND w.w_country = 'United States'
    AND cr.cr_return_quantity > 0
GROUP BY
    cp.cp_type,
    sm.sm_type,
    w.w_state
HAVING
    SUM(cr.cr_net_loss) > 1000
ORDER BY
    total_net_loss DESC
LIMIT 10
