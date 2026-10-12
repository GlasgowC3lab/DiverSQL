SELECT
    i.i_brand,
    d_sales.d_year AS sales_year,
    r.r_reason_desc,
    sm.sm_ship_mode_id,
    SUM(cs.cs_net_paid_inc_tax) AS total_sales,
    SUM(cr.cr_return_amt_inc_tax) AS total_returns,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_net_loss) / NULLIF(SUM(cs.cs_net_paid_inc_tax), 0) AS net_loss_ratio,
    COUNT(cr.cr_order_number) AS return_count,
    AVG(td.t_hour) AS avg_return_hour
FROM
    catalog_sales cs
JOIN
    item i ON cs.cs_item_sk = i.i_item_sk
JOIN
    date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
LEFT JOIN
    catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
LEFT JOIN
    date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
LEFT JOIN
    reason r ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN
    ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN
    time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
LEFT JOIN
    customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
WHERE
    d_sales.d_year = 2001
    AND cr.cr_reason_sk IN (17, 16, 59)
    AND cr.cr_call_center_sk IN (19, 40)
    AND cd.cd_gender = 'M'
GROUP BY
    i.i_brand,
    d_sales.d_year,
    r.r_reason_desc,
    sm.sm_ship_mode_id
ORDER BY
    net_loss_ratio DESC
LIMIT 100
