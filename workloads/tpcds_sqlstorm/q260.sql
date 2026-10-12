SELECT t.year, t.store_state, t.total_profit, t.profit_rank
FROM (
   SELECT d.d_year AS year,
          s.s_state AS store_state,
          SUM(ss.ss_net_profit) AS total_profit,
          RANK() OVER (ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   GROUP BY d.d_year, s.s_state
) t
WHERE t.profit_rank <= 10
ORDER BY t.total_profit DESC
