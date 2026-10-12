SELECT
    cc.cc_call_center_id,
    cc.cc_company_name,
    cc.cc_state,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(CASE WHEN sr.sr_returned_date_sk IS NOT NULL THEN sr.sr_net_loss ELSE 0 END) AS total_return_loss,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_return_tickets,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(sr.sr_return_quantity) AS total_quantity_returned
FROM store_sales ss
LEFT JOIN store_returns sr
    ON ss.ss_item_sk = sr.sr_item_sk
   AND ss.ss_ticket_number = sr.sr_ticket_number
JOIN call_center cc
    ON ss.ss_store_sk = cc.cc_call_center_sk
WHERE ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
  AND cc.cc_company = 1
  AND cc.cc_class = 'large'
GROUP BY
    cc.cc_call_center_id,
    cc.cc_company_name,
    cc.cc_state
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
