SELECT
    sm.sm_carrier,
    ws.web_country,
    d.d_year,
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(*) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_fee) AS avg_fee,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
    AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
    SUM(CASE WHEN cr.cr_store_credit > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS pct_store_credit_used
FROM
    catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd
    ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
WHERE
    d.d_year = 2002
    AND cr.cr_return_quantity > 10
    AND cr.cr_store_credit >= 20.00
    AND sm.sm_type IN ('AIR', 'GROUND')
    AND ws.web_country = 'United States'
GROUP BY
    sm.sm_carrier,
    ws.web_country,
    d.d_year,
    cd.cd_gender,
    cd.cd_marital_status
HAVING
    COUNT(*) > 50
ORDER BY
    total_net_loss DESC
LIMIT 20
