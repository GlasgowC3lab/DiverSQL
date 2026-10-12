WITH sales AS (
  SELECT
    s.s_store_sk,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    i.i_item_sk,
    i.i_product_name,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_quantity) AS total_quantity,
    AVG(ss.ss_ext_discount_amt) AS avg_discount
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_month_seq, i.i_item_sk, i.i_product_name
),
returns AS (
  SELECT
    s.s_store_sk,
    d.d_year,
    d.d_month_seq,
    i.i_item_sk,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_return_loss,
    SUM(sr.sr_return_quantity) AS total_return_quantity
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  GROUP BY s.s_store_sk, d.d_year, d.d_month_seq, i.i_item_sk
),
sales_with_returns AS (
  SELECT
    s.*,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    (s.total_sales - COALESCE(r.total_return_amount, 0)) AS net_sales,
    (s.total_profit - COALESCE(r.total_return_loss, 0)) AS net_profit
  FROM sales s
  LEFT JOIN returns r
    ON s.s_store_sk = r.s_store_sk
   AND s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
   AND s.i_item_sk = r.i_item_sk
),
ranked_items AS (
  SELECT
    swr.*,
    DENSE_RANK() OVER (PARTITION BY swr.s_store_sk, swr.d_year ORDER BY swr.net_profit DESC) AS profit_rank,
    SUM(swr.net_profit) OVER (PARTITION BY swr.s_store_sk ORDER BY swr.d_year, swr.d_month_seq ROWS UNBOUNDED PRECEDING) AS cumulative_profit
  FROM sales_with_returns swr
)
SELECT
  r.s_store_sk,
  r.s_store_name,
  r.d_year,
  r.d_month_seq,
  r.i_item_sk,
  r.i_product_name,
  r.total_quantity,
  r.total_sales,
  r.total_return_quantity,
  r.total_return_amount,
  r.net_sales,
  r.net_profit,
  r.avg_discount,
  r.profit_rank,
  r.cumulative_profit
FROM ranked_items r
WHERE r.profit_rank <= 3
ORDER BY r.s_store_sk, r.d_year, r.profit_rank
