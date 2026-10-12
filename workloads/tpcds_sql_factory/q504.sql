SELECT s.s_store_id,
       s.s_store_name,
       s.s_city,
       s.s_state,
       COUNT(DISTINCT sw.ss_ticket_number) AS distinct_tickets,
       SUM(sw.ss_ext_sales_price) AS total_sales_amount,
       SUM(COALESCE(sr.sr_return_amt, 0)) AS total_returns_amount,
       SUM(sw.ss_ext_sales_price) - SUM(COALESCE(sr.sr_return_amt, 0)) AS net_sales,
       ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY SUM(sw.ss_ext_sales_price) DESC) AS state_sales_rank
FROM store s
JOIN (SELECT ss.*, t.t_shift FROM store_sales ss JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk) sw
  ON sw.ss_store_sk = s.s_store_sk
LEFT JOIN store_returns sr
  ON sr.sr_store_sk = s.s_store_sk
  AND sr.sr_ticket_number = sw.ss_ticket_number
  AND sr.sr_item_sk = sw.ss_item_sk
WHERE sw.t_shift = 'Morning'
  AND s.s_state NOT IN ('CA', 'NY')
GROUP BY s.s_store_id, s.s_store_name, s.s_city, s.s_state
HAVING SUM(sw.ss_ext_sales_price) > 500000
ORDER BY net_sales DESC
LIMIT 25
