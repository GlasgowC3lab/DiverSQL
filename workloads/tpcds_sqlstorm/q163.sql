SELECT d.d_year AS year,
       s.s_state AS state,
       i.i_category AS category,
       cd.cd_gender AS gender,
       p.p_promo_name AS promo_name,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       SUM(ss.ss_net_profit) AS total_profit,
       COUNT(DISTINCT ss.ss_ticket_number) AS order_count,
       AVG(ss.ss_quantity) AS avg_quantity,
       SUM(ss.ss_ext_discount_amt) AS total_discount
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
WHERE d.d_year BETWEEN 1999 AND 2001
  AND s.s_gmt_offset > -5
  AND p.p_discount_active = 'Y'
  AND cd.cd_gender = 'M'
GROUP BY d.d_year,
         s.s_state,
         i.i_category,
         cd.cd_gender,
         p.p_promo_name
ORDER BY total_sales DESC
LIMIT 100
