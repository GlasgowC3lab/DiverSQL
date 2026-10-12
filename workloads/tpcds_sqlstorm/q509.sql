WITH sales_agg AS (
 SELECT
   d.d_year,
   i.i_brand,
   s.s_state,
   SUM(ss.ss_net_paid) AS total_net_paid,
   SUM(ss.ss_net_profit) AS total_net_profit,
   AVG(ss.ss_quantity) AS avg_quantity,
   SUM(ss.ss_ext_sales_price) AS total_ext_sales_price
 FROM
   store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
 WHERE
   d.d_year BETWEEN 2000 AND 2002
 GROUP BY
   d.d_year,
   i.i_brand,
   s.s_state
)
SELECT
  d_year,
  i_brand,
  s_state,
  total_net_paid,
  total_net_profit,
  avg_quantity,
  total_ext_sales_price,
  RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
WHERE total_net_paid > 1000000
ORDER BY d_year, profit_rank
LIMIT 200
