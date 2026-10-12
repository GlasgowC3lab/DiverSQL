SELECT
    d.d_year,
    d.d_moy AS month,
    s.s_state AS store_state,
    w.w_state AS warehouse_state,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_orders,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    SUM(wr.wr_return_amt) AS web_return_amount,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    SUM(wr.wr_net_loss) AS web_net_loss,
    (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
    AVG(wr.wr_return_quantity) AS avg_web_return_qty,
    CASE
        WHEN (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) = 0 THEN 0
        ELSE SUM(cr.cr_return_amount) / (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss))
    END AS return_to_loss_ratio
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2020 AND 2023
GROUP BY d.d_year, d.d_moy, s.s_state, w.w_state
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY d.d_year DESC, d.d_moy ASC
LIMIT 100
