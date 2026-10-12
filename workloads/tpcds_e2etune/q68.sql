SELECT
    ss.ss_store_sk AS store_id,
    substr(cast(ss.ss_sold_date_sk as varchar), 1, 6) AS year_month,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
    SUM(ss.ss_net_paid_inc_tax) AS total_sales_amount,
    SUM(ss.ss_net_profit) AS total_sales_profit,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_transactions,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_return_loss,
    (SUM(ss.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0)) AS net_profit_after_returns,
    RANK() OVER (PARTITION BY substr(cast(ss.ss_sold_date_sk as varchar), 1, 6) ORDER BY (SUM(ss.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0)) DESC) AS store_monthly_profit_rank
FROM store_sales ss
LEFT JOIN store_returns sr
    ON ss.ss_item_sk = sr.sr_item_sk
   AND ss.ss_ticket_number = sr.sr_ticket_number
   AND (sr.sr_return_time_sk IN (60517, 52104, 42770) OR sr.sr_return_time_sk IS NULL)
   AND (sr.sr_return_amt > 50 OR sr.sr_return_amt IS NULL)
WHERE ss.ss_sold_date_sk BETWEEN 20000101 AND 20231231
  AND ss.ss_net_paid_inc_tax > 0
GROUP BY ss.ss_store_sk, substr(cast(ss.ss_sold_date_sk as varchar), 1, 6)
HAVING SUM(ss.ss_net_paid_inc_tax) > 5000
ORDER BY net_profit_after_returns DESC
LIMIT 50
