SELECT s.s_store_id, s.s_store_name, s.s_state, s.s_city, SUM(sw.ss_net_profit) AS total_sales_profit,
       COALESCE(SUM(sr.sr_net_loss), 0) AS total_return_loss,
       SUM(sw.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) AS net_margin,
       CASE WHEN SUM(sw.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) >= 300000 THEN 'VERY HIGH'
            WHEN SUM(sw.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) BETWEEN 150000 AND 299999.99 THEN 'HIGH'
            WHEN SUM(sw.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) BETWEEN 50000 AND 149999.99 THEN 'MEDIUM'
            ELSE 'LOW' END AS profit_tier,
       RANK() OVER (ORDER BY SUM(sw.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) DESC) AS profit_rank,
       DENSE_RANK() OVER (PARTITION BY s.s_state ORDER BY SUM(sw.ss_net_profit) DESC) AS state_store_rank
FROM store s
JOIN (SELECT ss.*, t.t_shift FROM store_sales ss JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk) sw
  ON sw.ss_store_sk = s.s_store_sk
LEFT JOIN store_returns sr
  ON sr.sr_store_sk = s.s_store_sk
  AND sr.sr_ticket_number = sw.ss_ticket_number
  AND sr.sr_item_sk = sw.ss_item_sk
WHERE sw.t_shift IN ('Evening', 'Night')
  AND s.s_country = 'United States'
GROUP BY s.s_store_id, s.s_store_name, s.s_state, s.s_city
ORDER BY net_margin DESC
LIMIT 30
