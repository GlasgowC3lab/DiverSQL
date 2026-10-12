WITH agg AS (
  SELECT s.s_store_id,
         d.d_year,
         p.p_promo_id,
         i.i_category,
         i.i_class,
         SUM(ss.ss_net_profit) AS total_profit,
         SUM(ss.ss_ext_sales_price) AS total_sales,
         AVG(ss.ss_coupon_amt) AS avg_coupon,
         COUNT(*) AS order_cnt
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
    AND s.s_country = 'United States'
  GROUP BY s.s_store_id, d.d_year, p.p_promo_id, i.i_category, i.i_class
  HAVING SUM(ss.ss_net_profit) > 0
)
SELECT *,
       ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY d_year, profit_rank
LIMIT 100
