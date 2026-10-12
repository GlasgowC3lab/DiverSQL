SELECT
  d.d_year,
  d.d_month_seq AS month,
  s.s_state,
  i.i_category,
  p.p_channel_tv,
  SUM(ss.ss_net_profit) AS total_net_profit,
  SUM(ss.ss_net_paid) AS total_net_paid,
  AVG(ss.ss_quantity) AS avg_quantity,
  COUNT(DISTINCT ss.ss_ticket_number) AS distinct_orders,
  SUM(CASE WHEN cd.cd_gender = 'F' THEN ss.ss_ext_sales_price ELSE 0 END) AS female_sales,
  SUM(CASE WHEN cd.cd_gender = 'M' THEN ss.ss_ext_sales_price ELSE 0 END) AS male_sales
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
WHERE d.d_year BETWEEN 1999 AND 2001
  AND p.p_discount_active = 'Y'
GROUP BY d.d_year, d.d_month_seq, s.s_state, i.i_category, p.p_channel_tv
ORDER BY d.d_year, d.d_month_seq, s.s_state, i.i_category
