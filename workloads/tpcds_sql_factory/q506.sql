SELECT s.s_store_id,
       s.s_store_name,
       s.s_city,
       s.s_state,
       SUM(sw.ss_net_profit) AS total_profit,
       SUM(COALESCE(sr.sr_net_loss, 0)) AS total_loss,
       SUM(sw.ss_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0)) AS net_margin,
       CASE WHEN SUM(sw.ss_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0)) >= 250000 THEN 'A'
            WHEN SUM(sw.ss_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0)) >= 150000 THEN 'B'
            WHEN SUM(sw.ss_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0)) >= 50000 THEN 'C'
            ELSE 'D' END AS tier,
       RANK() OVER (ORDER BY (SUM(sw.ss_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0))) ASC) AS profit_rank_asc,
       SUM(sw.ss_quantity) AS total_quantity_sold,
       SUM(sr.sr_return_quantity) FILTER (WHERE sr.sr_return_quantity IS NOT NULL) AS total_return_quantity
FROM store s
JOIN (SELECT ss.*, t.t_shift FROM store_sales ss JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk) sw
  ON sw.ss_store_sk = s.s_store_sk
LEFT JOIN store_returns sr
  ON sr.sr_store_sk = s.s_store_sk
  AND sr.sr_ticket_number = sw.ss_ticket_number
  AND sr.sr_item_sk = sw.ss_item_sk
WHERE sw.t_shift = 'Midday' AND s.s_state = 'TX'
GROUP BY s.s_store_id, s.s_store_name, s.s_city, s.s_state
ORDER BY tier, net_margin DESC
LIMIT 20
