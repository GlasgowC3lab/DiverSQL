WITH sales_agg AS (
   SELECT
     s.s_store_sk,
     s.s_state,
     d.d_year,
     SUM(ss.ss_net_profit) AS total_sales_profit
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   WHERE d.d_year BETWEEN 1998 AND 2002
   GROUP BY s.s_store_sk, s.s_state, d.d_year
),
returns_agg AS (
   SELECT
     s.s_store_sk,
     d.d_year,
     SUM(sr.sr_net_loss) AS total_return_loss
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   WHERE d.d_year BETWEEN 1998 AND 2002
   GROUP BY s.s_store_sk, d.d_year
),
store_year_profit AS (
   SELECT
     s.s_store_sk,
     s.s_state,
     s.d_year,
     s.total_sales_profit,
     COALESCE(r.total_return_loss, 0) AS total_return_loss,
     s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns
   FROM sales_agg s
   LEFT JOIN returns_agg r
     ON s.s_store_sk = r.s_store_sk
    AND s.d_year = r.d_year
),
ranked AS (
   SELECT
     d_year,
     s_state,
     s_store_sk,
     net_profit_after_returns,
     RANK() OVER (PARTITION BY d_year ORDER BY net_profit_after_returns DESC) AS profit_rank
   FROM store_year_profit
)
SELECT d_year, s_state, s_store_sk, net_profit_after_returns, profit_rank
FROM ranked
WHERE profit_rank <= 10
ORDER BY d_year, profit_rank
