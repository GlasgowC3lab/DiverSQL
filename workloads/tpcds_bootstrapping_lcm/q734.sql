SELECT
  cp.cp_department,
  cp.cp_type,
  s.s_city,
  s.s_state,
  d_sales.d_year,
  d_sales.d_month_seq,
  ws.web_name,
  ws.web_market_manager,
  CASE
    WHEN d_sales.d_month_seq BETWEEN 1 AND 6 THEN 'First Half'
    ELSE 'Second Half'
  END AS half_year,
  SUM(ss.ss_ext_sales_price) AS total_sales,
  SUM(ss.ss_net_profit) AS total_net_profit,
  AVG(ss.ss_ext_discount_amt) AS avg_discount,
  COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
  SUM(ss.ss_quantity) AS total_quantity
FROM store_sales ss
JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d_sales.d_date_sk
JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_sales.d_date_sk
JOIN date_dim d_web_close ON ws.web_close_date_sk = d_web_close.d_date_sk
WHERE d_sales.d_year BETWEEN 2015 AND 2020
  AND s.s_state = 'CA'
  AND cp.cp_type = 'PROMO'
GROUP BY
  cp.cp_department,
  cp.cp_type,
  s.s_city,
  s.s_state,
  d_sales.d_year,
  d_sales.d_month_seq,
  ws.web_name,
  ws.web_market_manager,
  CASE
    WHEN d_sales.d_month_seq BETWEEN 1 AND 6 THEN 'First Half'
    ELSE 'Second Half'
  END
ORDER BY total_net_profit DESC
LIMIT 100
