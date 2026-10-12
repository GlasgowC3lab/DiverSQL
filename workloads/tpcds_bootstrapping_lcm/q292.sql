SELECT
    d.d_year AS year,
    s.s_state AS state,
    CASE
        WHEN hd_cat.hd_buy_potential = 'High' AND hd_web.hd_buy_potential = 'Low' THEN 'High-Low'
        WHEN hd_cat.hd_buy_potential = hd_web.hd_buy_potential THEN CONCAT('Same-', hd_cat.hd_buy_potential)
        ELSE CONCAT(hd_cat.hd_buy_potential, '-', hd_web.hd_buy_potential)
    END AS demographic_pair,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_orders,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    SUM(wr.wr_net_loss) AS web_net_loss,
    SUM(cr.cr_return_amt_inc_tax) + SUM(wr.wr_return_amt_inc_tax) AS total_return_inc_tax,
    AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
    AVG(wr.wr_return_quantity) AS avg_web_return_qty,
    (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) / NULLIF(COUNT(*), 0) AS avg_loss_per_row,
    CASE WHEN (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) > 0 THEN 1 ELSE 0 END AS positive_loss_flag
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd_cat ON cr.cr_refunded_hdemo_sk = hd_cat.hd_demo_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd_web ON wr.wr_refunded_hdemo_sk = hd_web.hd_demo_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY
    d.d_year,
    s.s_state,
    CASE
        WHEN hd_cat.hd_buy_potential = 'High' AND hd_web.hd_buy_potential = 'Low' THEN 'High-Low'
        WHEN hd_cat.hd_buy_potential = hd_web.hd_buy_potential THEN CONCAT('Same-', hd_cat.hd_buy_potential)
        ELSE CONCAT(hd_cat.hd_buy_potential, '-', hd_web.hd_buy_potential)
    END
HAVING SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) > 0
ORDER BY total_return_inc_tax DESC
LIMIT 100
