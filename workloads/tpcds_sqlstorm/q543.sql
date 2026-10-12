WITH sales_agg AS (
  SELECT s.s_store_sk,
         s.s_store_name,
         d.d_year,
         d.d_moy AS month_num,
         i.i_category,
         SUM(ss.ss_ext_sales_price) AS total_sales,
         SUM(ss.ss_net_profit) AS total_profit,
         COUNT(*) AS txn_count,
         COUNT(DISTINCT p.p_promo_id) AS promo_count
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year = 1998
  GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_moy, i.i_category
  HAVING SUM(ss.ss_ext_sales_price) > 100000
)
SELECT s_store_sk,
       s_store_name,
       d_year,
       month_num,
       i_category,
       total_sales,
       total_profit,
       txn_count,
       promo_count,
       RANK() OVER (PARTITION BY s_store_sk, d_year, month_num ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY s_store_name, d_year, month_num, total_sales DESC
