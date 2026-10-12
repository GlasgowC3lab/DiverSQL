WITH sales AS (
  SELECT
    s.s_state AS state,
    d.d_month_seq AS month_seq,
    i.i_category AS category,
    SUM(ss.ss_ext_sales_price) AS sales_amount,
    SUM(ss.ss_net_profit) AS profit,
    COUNT(DISTINCT ss.ss_customer_sk) AS customers
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY s.s_state, d.d_month_seq, i.i_category
), returns AS (
  SELECT
    s.s_state AS state,
    d.d_month_seq AS month_seq,
    i.i_category AS category,
    SUM(sr.sr_return_amt) AS return_amount,
    SUM(sr.sr_net_loss) AS return_loss
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY s.s_state, d.d_month_seq, i.i_category
)
SELECT
  s.state,
  s.month_seq,
  s.category,
  s.sales_amount,
  COALESCE(r.return_amount, 0) AS return_amount,
  s.sales_amount - COALESCE(r.return_amount, 0) AS net_sales,
  s.profit,
  s.customers
FROM sales s
LEFT JOIN returns r
  ON s.state = r.state
  AND s.month_seq = r.month_seq
  AND s.category = r.category
ORDER BY s.state, s.month_seq, s.sales_amount DESC
LIMIT 100
