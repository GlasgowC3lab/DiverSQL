SELECT
    ss.ss_store_sk AS store_id,
    td.t_hour,
    td.t_shift,
    COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
    SUM(ss.ss_ext_sales_price) AS gross_sales,
    SUM(ss.ss_net_profit) AS gross_profit,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_returns,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss,
    (SUM(ss.ss_ext_sales_price) - SUM(COALESCE(sr.sr_return_amt, 0))) AS net_sales,
    (SUM(ss.ss_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0))) AS net_profit,
    ROUND(100.0 * SUM(COALESCE(sr.sr_return_amt, 0)) / NULLIF(SUM(ss.ss_ext_sales_price), 0), 2) AS return_rate_pct
FROM store_sales ss
JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
   AND ss.ss_item_sk = sr.sr_item_sk
   AND ss.ss_customer_sk = sr.sr_customer_sk
WHERE c.c_birth_country = 'MEXICO'
  AND td.t_hour BETWEEN 12 AND 18
GROUP BY ss.ss_store_sk, td.t_hour, td.t_shift
HAVING SUM(ss.ss_ext_sales_price) > 5000
ORDER BY net_profit DESC
LIMIT 50
