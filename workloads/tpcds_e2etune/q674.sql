SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cp.cp_type,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss,
    COUNT(DISTINCT c1.c_customer_sk) AS distinct_customers,
    SUM(cs.cs_ext_discount_amt) / NULLIF(SUM(cs.cs_ext_list_price), 0) AS avg_discount_rate
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c1 ON cs.cs_bill_customer_sk = c1.c_customer_sk
LEFT JOIN web_returns wr ON wr.wr_refunded_customer_sk = c1.c_customer_sk
LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
WHERE
    cc.cc_market_manager = 'Julius Tran'
    AND cp.cp_type = 'A'
    AND cs.cs_sold_date_sk BETWEEN 2451910 AND 2452000
    AND (r.r_reason_desc IS NULL OR r.r_reason_desc NOT LIKE '%fraud%')
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    cp.cp_type
HAVING
    SUM(cs.cs_net_profit) > 1000000
ORDER BY
    total_net_profit DESC
LIMIT 10
