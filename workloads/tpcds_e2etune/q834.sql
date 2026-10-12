SELECT
    p.p_promo_name,
    w.w_state,
    COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
    (SUM(cs.cs_net_profit) - SUM(COALESCE(cr.cr_net_loss, 0))) AS net_profit_after_returns
FROM catalog_sales cs
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN catalog_returns cr ON cs.cs_item_sk = cr.cr_item_sk
    AND cs.cs_order_number = cr.cr_order_number
WHERE cs.cs_sold_date_sk BETWEEN 2451910 AND 2452275
  AND cd.cd_gender = 'F'
  AND (cr.cr_returned_time_sk IS NULL OR cr.cr_returned_time_sk IN (45816, 74710, 71104))
GROUP BY p.p_promo_name, w.w_state
HAVING SUM(cs.cs_net_profit) > 10000
ORDER BY net_profit_after_returns DESC
LIMIT 100
