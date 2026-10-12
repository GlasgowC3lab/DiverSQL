SELECT
    cc.cc_name AS call_center_name,
    r.r_reason_desc AS return_reason,
    sm.sm_type AS ship_mode_type,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    SUM(ss.ss_net_paid) AS total_sales_net_paid,
    AVG(ss.ss_net_profit) AS avg_sales_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales_transactions,
    SUM(ss.ss_quantity) AS total_sales_quantity,
    (SUM(cr.cr_return_amount) / NULLIF(SUM(ss.ss_net_paid), 0)) * 100 AS return_to_sales_pct
FROM catalog_returns cr
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
JOIN store_sales ss ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2452000
  AND cc.cc_class = 'large'
  AND cd.cd_gender = 'M'
GROUP BY cc.cc_name, r.r_reason_desc, sm.sm_type
HAVING COUNT(DISTINCT cr.cr_order_number) > 5
ORDER BY total_return_amount_inc_tax DESC
LIMIT 100
