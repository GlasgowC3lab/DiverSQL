SELECT
    cc.cc_company_name,
    cp.cp_type,
    date_trunc('month', date_add('day', cs.cs_sold_date_sk, date '1970-01-01')) AS sold_month,
    SUM(cs.cs_net_paid_inc_ship) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss,
    SUM(cs.cs_quantity) AS total_quantity,
    SUM(COALESCE(cr.cr_return_quantity, 0)) AS total_return_quantity,
    SUM(cs.cs_quantity) - SUM(COALESCE(cr.cr_return_quantity, 0)) AS net_quantity,
    SUM(cs.cs_net_profit) - SUM(COALESCE(cr.cr_net_loss, 0)) AS net_profit,
    CASE WHEN SUM(cs.cs_quantity) > 0 THEN
        SUM(COALESCE(cr.cr_return_quantity, 0)) / SUM(cs.cs_quantity)
    ELSE 0 END AS return_rate,
    RANK() OVER (PARTITION BY cp.cp_type ORDER BY SUM(cs.cs_net_profit) - SUM(COALESCE(cr.cr_net_loss, 0)) DESC) AS profit_rank
FROM
    catalog_sales cs
JOIN
    call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN
    catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN
    catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
        AND cs.cs_call_center_sk = cr.cr_call_center_sk
        AND cs.cs_catalog_page_sk = cr.cr_catalog_page_sk
WHERE
    cc.cc_gmt_offset = -5.00
    AND cp.cp_type = 'A'
    AND cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
GROUP BY
    cc.cc_company_name,
    cp.cp_type,
    date_trunc('month', date_add('day', cs.cs_sold_date_sk, date '1970-01-01'))
HAVING
    SUM(cs.cs_net_paid_inc_ship) > 10000
ORDER BY
    net_profit DESC
LIMIT 100
