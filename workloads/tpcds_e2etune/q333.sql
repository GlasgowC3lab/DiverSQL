SELECT
    s.s_store_id,
    s.s_market_id,
    t.t_hour,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    SUM(ss.ss_net_paid) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss,
    (SUM(ss.ss_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0))) AS net_profit_after_returns,
    (SUM(COALESCE(sr.sr_return_quantity, 0)) / NULLIF(SUM(ss.ss_quantity), 0)) * 100 AS return_rate_pct
FROM store_sales ss
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
LEFT JOIN store_returns sr
  ON ss.ss_ticket_number = sr.sr_ticket_number
  AND ss.ss_store_sk = sr.sr_store_sk
  AND ss.ss_item_sk = sr.sr_item_sk
WHERE s.s_country = 'United States'
  AND t.t_shift = 'Evening'
  AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2451053
GROUP BY s.s_store_id, s.s_market_id, t.t_hour
HAVING COUNT(DISTINCT ss.ss_ticket_number) >= 10
ORDER BY net_profit_after_returns DESC
LIMIT 100
