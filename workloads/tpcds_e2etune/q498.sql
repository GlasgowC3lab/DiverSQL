SELECT
    cc.cc_name AS call_center_name,
    cd.cd_gender AS customer_gender,
    cs.cs_sold_date_sk AS sales_date_key,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    COALESCE(SUM(cr.cr_return_quantity), 0) AS total_quantity_returned,
    (SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0)) AS net_profit_after_returns,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount
FROM catalog_sales cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cs.cs_item_sk = cr.cr_item_sk
WHERE cc.cc_gmt_offset = -6.00
  AND cc.cc_employees > 2000000
  AND cc.cc_rec_end_date >= DATE '2000-01-01'
GROUP BY
    cc.cc_name,
    cd.cd_gender,
    cs.cs_sold_date_sk
HAVING SUM(cs.cs_net_profit) > 10000
ORDER BY net_profit_after_returns DESC
LIMIT 100
