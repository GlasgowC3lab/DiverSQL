SELECT
    cc.cc_division_name,
    cc.cc_market_manager,
    d.d_year,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_orders,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(cr.cr_return_quantity) AS total_catalog_return_quantity,
    SUM(wr.wr_return_quantity) AS total_web_return_quantity,
    (SUM(cr.cr_return_quantity) + SUM(wr.wr_return_quantity)) AS total_return_quantity,
    COUNT(DISTINCT s.s_store_id) AS distinct_stores,
    AVG(s.s_floor_space) AS avg_store_floor_space,
    SUM(cr.cr_fee) + SUM(wr.wr_fee) AS total_fees,
    CASE
        WHEN SUM(cr.cr_return_amount) > 0 THEN SUM(cr.cr_net_loss) / SUM(cr.cr_return_amount)
        ELSE NULL
    END AS catalog_loss_ratio,
    CASE
        WHEN SUM(wr.wr_return_amt) > 0 THEN SUM(wr.wr_net_loss) / SUM(wr.wr_return_amt)
        ELSE NULL
    END AS web_loss_ratio,
    (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) /
        NULLIF((SUM(cr.cr_return_quantity) + SUM(wr.wr_return_quantity)), 0) AS avg_loss_per_return
FROM date_dim d
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
    AND cc.cc_closed_date_sk = d.d_date_sk
    AND cc.cc_open_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY cc.cc_division_name, cc.cc_market_manager, d.d_year
ORDER BY total_catalog_return_amount DESC
LIMIT 100
