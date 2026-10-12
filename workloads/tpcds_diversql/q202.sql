WITH
  sales_agg AS (
    SELECT
      s.s_store_id,
      i.i_category,
      SUM(ss.ss_ext_sales_price)            AS total_sales,
      COUNT(*)                               AS sales_transactions,
      'sales'                                 AS record_type
    FROM store_sales ss
    JOIN store s               ON ss.ss_store_sk = s.s_store_sk
    JOIN item i                ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t            ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND i.i_brand = 'brandnameless #5'
      AND cd.cd_credit_rating = 'Good'
      AND s.s_manager = 'Wayne Coleman'
      AND i.i_rec_start_date >= DATE '2001-01-01'
    GROUP BY s.s_store_id, i.i_category
  ),
  returns_agg AS (
    SELECT
      s.s_store_id,
      i.i_category,
      SUM(sr.sr_return_amt)                 AS total_return,
      COUNT(*)                               AS return_transactions,
      'return'                               AS record_type
    FROM store_returns sr
    JOIN store s               ON sr.sr_store_sk = s.s_store_sk
    JOIN item i                ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim t            ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND i.i_brand = 'brandnameless #5'
      AND cd.cd_credit_rating = 'Good'
      AND s.s_manager = 'Wayne Coleman'
      AND i.i_rec_start_date >= DATE '2001-01-01'
    GROUP BY s.s_store_id, i.i_category
  )
SELECT
  s_store_id,
  i_category,
  total_sales,
  sales_transactions,
  record_type
FROM sales_agg
UNION ALL
SELECT
  s_store_id,
  i_category,
  total_return        AS total_sales,
  return_transactions AS sales_transactions,
  record_type
FROM returns_agg
ORDER BY s_store_id, i_category, record_type
LIMIT 100
