SELECT
    w.w_state AS warehouse_state,
    r.r_reason_desc AS return_reason,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(ss.ss_sales_price) AS avg_store_sales_price,
    SUM(ws.ws_net_paid_inc_tax) AS total_web_sales_inc_tax
FROM store_returns sr
JOIN store_sales ss
    ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2459000
  AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2459000
  AND r.r_reason_desc LIKE '%damaged%'
  AND w.w_state IN ('CA', 'TX')
GROUP BY w.w_state, r.r_reason_desc
HAVING SUM(sr.sr_return_amt_inc_tax) > 1000
ORDER BY total_return_amount_inc_tax DESC
LIMIT 100
