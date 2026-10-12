SELECT
  d.d_year,
  s.s_state,
  COUNT(DISTINCT ss.ss_ticket_number) AS num_orders,
  SUM(ss.ss_ext_sales_price) AS total_sales,
  SUM(ss.ss_net_profit) AS total_profit,
  AVG(ss.ss_ext_discount_amt) AS avg_discount,
  SUM(ss.ss_quantity) AS total_quantity
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
WHERE d.d_year BETWEEN 1999 AND 2001
  AND s.s_state IN ('CA', 'TX', 'NY')
GROUP BY d.d_year, s.s_state
ORDER BY d.d_year, s.s_state
