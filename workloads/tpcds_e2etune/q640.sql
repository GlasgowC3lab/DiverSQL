WITH sales_agg AS (
  SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    i.i_category,
    i.i_brand,
    date_trunc('month', from_unixtime(t.t_time)) AS month,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_net_profit) AS net_profit,
    COUNT(*) AS sales_cnt
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  WHERE s.s_country = 'United States'
    AND i.i_category = 'Electronics'
    AND t.t_hour BETWEEN 9 AND 21
  GROUP BY s.s_store_id, s.s_store_name, s.s_state, i.i_category, i.i_brand, date_trunc('month', from_unixtime(t.t_time))
),
returns_agg AS (
  SELECT
    s.s_store_id,
    i.i_category,
    i.i_brand,
    date_trunc('month', from_unixtime(t.t_time)) AS month,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
    SUM(sr.sr_return_quantity) AS total_return_qty,
    COUNT(*) AS return_cnt
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  WHERE s.s_country = 'United States'
    AND i.i_category = 'Electronics'
    AND t.t_hour BETWEEN 9 AND 21
  GROUP BY s.s_store_id, i.i_category, i.i_brand, date_trunc('month', from_unixtime(t.t_time))
)
SELECT
  sa.s_store_id,
  sa.s_store_name,
  sa.s_state,
  sa.month,
  sa.i_category,
  sa.i_brand,
  sa.total_sales,
  sa.total_discount,
  sa.net_profit,
  COALESCE(ra.total_return_amount, 0) AS total_return_amount,
  COALESCE(ra.total_return_qty, 0) AS total_return_qty,
  CASE WHEN sa.total_sales > 0 THEN COALESCE(ra.total_return_amount, 0) / sa.total_sales ELSE 0 END AS return_rate,
  ROUND(sa.net_profit / NULLIF(sa.total_sales, 0), 4) AS profit_margin,
  RANK() OVER (PARTITION BY sa.month ORDER BY sa.net_profit DESC) AS profit_rank
FROM sales_agg sa
LEFT JOIN returns_agg ra
  ON sa.s_store_id = ra.s_store_id
  AND sa.i_category = ra.i_category
  AND sa.i_brand = ra.i_brand
  AND sa.month = ra.month
ORDER BY sa.month DESC, profit_rank ASC
LIMIT 100
