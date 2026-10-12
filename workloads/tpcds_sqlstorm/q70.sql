SELECT
  d.d_year,
  s.s_store_name,
  i.i_category,
  SUM(ss.ss_net_paid) AS total_net_paid,
  SUM(ss.ss_net_profit) AS total_net_profit,
  COUNT(DISTINCT ss.ss_ticket_number) AS distinct_orders
FROM
  store_sales ss
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
WHERE
  d.d_year BETWEEN 1999 AND 2001
  AND s.s_state = 'CA'
  AND i.i_manager_id IS NOT NULL
GROUP BY
  d.d_year,
  s.s_store_name,
  i.i_category
ORDER BY
  d.d_year,
  total_net_paid DESC
LIMIT 100
