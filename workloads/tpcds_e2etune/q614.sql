WITH inv_agg AS (
    SELECT inv_warehouse_sk, AVG(inv_quantity_on_hand) AS avg_qty_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT
    w.w_city AS warehouse_city,
    wp.wp_type AS web_page_type,
    COUNT(*) AS total_returns,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    i.avg_qty_on_hand,
    SUM(CASE WHEN c_returning.c_current_hdemo_sk <> cr.cr_returning_hdemo_sk THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS pct_diff_hhdemo,
    SUM(CASE WHEN hd_returning.hd_buy_potential <> hd_current.hd_buy_potential THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS pct_buy_potential_change,
    RANK() OVER (PARTITION BY w.w_city ORDER BY SUM(cr.cr_net_loss) DESC) AS net_loss_rank
FROM catalog_returns cr
JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
JOIN customer c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN household_demographics hd_current ON c_returning.c_current_hdemo_sk = hd_current.hd_demo_sk
JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN inv_agg i ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON wp.wp_customer_sk = c_returning.c_customer_sk
WHERE
    cr.cr_return_amount > 500
    AND td.t_shift = 'Evening'
    AND hd_returning.hd_buy_potential = 'High'
GROUP BY
    w.w_city,
    wp.wp_type,
    i.avg_qty_on_hand
HAVING
    COUNT(*) >= 10
ORDER BY
    w.w_city,
    total_net_loss DESC
