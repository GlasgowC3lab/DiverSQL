SELECT
  d_year,
  s_state,
  i_category,
  i_brand,
  t_hour,
  total_profit,
  total_quantity,
  orders,
  RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM (
  SELECT
    d.d_year,
    s.s_state,
    i.i_category,
    i.i_brand,
    t.t_hour,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_quantity) AS total_quantity,
    COUNT(DISTINCT ss.ss_ticket_number) AS orders
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year BETWEEN 1998 AND 2000
    AND i.i_category = 'Women'
    AND s.s_state IN ('CA', 'TX', 'NY')
  GROUP BY d.d_year, s.s_state, i.i_category, i.i_brand, t.t_hour
  HAVING SUM(ss.ss_net_profit) > 0
) agg
ORDER BY total_profit DESC
LIMIT 100
