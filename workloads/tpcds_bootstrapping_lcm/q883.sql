SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    s.s_city,
    s.s_state,
    sm.sm_type,
    sm.sm_carrier,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT wr.wr_order_number) AS web_order_cnt,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(cr.cr_return_quantity) AS catalog_return_qty,
    SUM(wr.wr_return_quantity) AS web_return_qty,
    SUM(cr.cr_fee) AS total_catalog_fee,
    SUM(wr.wr_fee) AS total_web_fee,
    SUM(cr.cr_return_ship_cost) AS total_catalog_ship_cost,
    SUM(wr.wr_return_ship_cost) AS total_web_ship_cost,
    SUM(cr.cr_return_tax) AS total_catalog_tax,
    SUM(wr.wr_return_tax) AS total_web_tax,
    (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) AS total_combined_net_loss
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2022
GROUP BY
    d.d_date,
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    s.s_city,
    s.s_state,
    sm.sm_type,
    sm.sm_carrier
ORDER BY total_combined_net_loss DESC
LIMIT 100
