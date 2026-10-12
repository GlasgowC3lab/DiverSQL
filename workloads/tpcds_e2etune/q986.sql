SELECT
    sale_time.t_hour AS sale_hour,
    cd.cd_gender,
    SUM(ss.ss_net_paid_inc_tax) AS total_sales_inc_tax,
    SUM(sr.sr_return_amt_inc_tax) AS total_returns_inc_tax,
    SUM(ss.ss_net_profit) - SUM(sr.sr_net_loss) AS net_profit_after_returns,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns
FROM store_sales ss
JOIN time_dim sale_time
  ON ss.ss_sold_time_sk = sale_time.t_time_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN store_returns sr
  ON ss.ss_ticket_number = sr.sr_ticket_number
  AND ss.ss_item_sk = sr.sr_item_sk
LEFT JOIN time_dim return_time
  ON sr.sr_return_time_sk = return_time.t_time_sk
WHERE ss.ss_quantity > 1
  AND cd.cd_gender IN ('M', 'F')
  AND (sr.sr_return_quantity IS NULL OR sr.sr_return_quantity > 0)
GROUP BY sale_time.t_hour, cd.cd_gender
HAVING SUM(ss.ss_net_profit) - SUM(sr.sr_net_loss) > 0
ORDER BY net_profit_after_returns DESC
LIMIT 100
