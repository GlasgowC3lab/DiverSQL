SELECT
    d_ret.d_year AS year,
    d_ret.d_moy AS month,
    s.s_store_name AS store_name,
    cc.cc_name AS call_center_name,
    ws.web_name AS website_name,
    COUNT(*) AS return_count,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_net_loss) AS avg_net_loss,
    SUM(s.s_floor_space) AS total_floor_space,
    SUM(cc.cc_employees) AS total_employees,
    CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'Loss' ELSE 'Profit' END AS net_loss_indicator,
    SUM(sr.sr_return_amt) / NULLIF(SUM(s.s_floor_space), 0) AS return_per_sqft
FROM store_returns sr
JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
JOIN date_dim d_cc ON d_ret.d_year = d_cc.d_year AND d_ret.d_moy = d_cc.d_moy
JOIN call_center cc ON cc.cc_open_date_sk = d_cc.d_date_sk
JOIN date_dim d_ws ON d_ret.d_year = d_ws.d_year AND d_ret.d_moy = d_ws.d_moy
JOIN web_site ws ON ws.web_open_date_sk = d_ws.d_date_sk
GROUP BY
    d_ret.d_year,
    d_ret.d_moy,
    s.s_store_name,
    cc.cc_name,
    ws.web_name
