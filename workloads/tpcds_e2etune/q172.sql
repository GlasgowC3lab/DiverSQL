SELECT
  s.s_store_name,
  i.i_category,
  t.t_hour,
  SUM(ss.ss_net_profit) AS total_net_profit,
  AVG(ss.ss_ext_discount_amt) AS avg_discount,
  SUM(ss.ss_quantity) AS total_quantity,
  RANK() OVER (PARTITION BY s.s_store_name ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE d.d_date BETWEEN DATE '2022-10-01' AND DATE '2022-12-31'
  AND ss.ss_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
GROUP BY s.s_store_name, i.i_category, t.t_hour
HAVING SUM(ss.ss_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 10
