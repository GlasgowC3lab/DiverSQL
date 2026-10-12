WITH sales_agg AS (
  SELECT
    s.s_store_name AS store_name,
    i.i_category AS category,
    sum(ss.ss_net_paid) AS total_sales,
    sum(ss.ss_quantity) AS total_quantity,
    sum(ss.ss_net_profit) AS total_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year = 2000
  GROUP BY s.s_store_name, i.i_category
),
returns_agg AS (
  SELECT
    s.s_store_name AS store_name,
    i.i_category AS category,
    sum(sr.sr_return_amt) AS total_returns
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  GROUP BY s.s_store_name, i.i_category
)
SELECT
  sa.store_name,
  sa.category,
  sa.total_sales,
  sa.total_quantity,
  sa.total_profit,
  coalesce(ra.total_returns, 0) AS total_returns,
  sa.total_sales - coalesce(ra.total_returns, 0) AS net_sales
FROM sales_agg sa
LEFT JOIN returns_agg ra
  ON sa.store_name = ra.store_name
  AND sa.category = ra.category
ORDER BY total_sales DESC
LIMIT 50
