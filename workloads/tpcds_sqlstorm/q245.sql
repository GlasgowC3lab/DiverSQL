WITH sales AS (
 SELECT d.d_year AS year, s.s_state AS state,
  sum(ss.ss_net_paid_inc_tax) AS total_sales,
  sum(ss.ss_net_profit) AS total_profit
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN store s ON ss.ss_store_sk = s.s_store_sk
 GROUP BY d.d_year, s.s_state
),
returns AS (
 SELECT d.d_year AS year, s.s_state AS state,
  sum(sr.sr_net_loss) AS total_return_loss
 FROM store_returns sr
 JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
 JOIN store s ON sr.sr_store_sk = s.s_store_sk
 GROUP BY d.d_year, s.s_state
)
SELECT s.year,
       s.state,
       s.total_sales,
       s.total_profit,
       coalesce(r.total_return_loss, 0) AS total_return_loss,
       (s.total_sales - coalesce(r.total_return_loss, 0)) AS net_sales,
       rank() OVER (PARTITION BY s.year ORDER BY s.total_sales DESC) AS sales_rank
FROM sales s
LEFT JOIN returns r ON s.year = r.year AND s.state = r.state
WHERE s.total_sales > 0
ORDER BY s.year, s.total_sales DESC
LIMIT 100
