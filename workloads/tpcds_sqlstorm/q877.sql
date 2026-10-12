WITH sales_agg AS (
  SELECT
    s.s_store_sk,
    s.s_store_name,
    s.s_division_name,
    i.i_category,
    d.d_year,
    SUM(ss.ss_net_profit) AS total_sales_profit,
    SUM(CASE WHEN ss.ss_promo_sk IS NOT NULL THEN ss.ss_net_profit ELSE 0 END) AS promo_sales_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    COUNT(DISTINCT CASE WHEN ss.ss_promo_sk IS NOT NULL THEN ss.ss_ticket_number END) AS promo_transactions
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2000
  GROUP BY s.s_store_sk, s.s_store_name, s.s_division_name, i.i_category, d.d_year
),
returns_agg AS (
  SELECT
    sr.sr_store_sk AS store_sk,
    i.i_category,
    d.d_year,
    SUM(sr.sr_net_loss) AS total_return_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_return_transactions
  FROM store_returns sr
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2000
  GROUP BY sr.sr_store_sk, i.i_category, d.d_year
)
SELECT
  sa.s_store_name,
  sa.s_division_name,
  sa.i_category,
  sa.d_year,
  sa.total_sales_profit,
  COALESCE(ra.total_return_loss, 0) AS total_return_loss,
  sa.total_sales_profit - COALESCE(ra.total_return_loss, 0) AS net_profit_after_returns,
  sa.promo_sales_profit,
  sa.total_transactions,
  sa.promo_transactions,
  COALESCE(ra.total_return_transactions, 0) AS total_return_transactions
FROM sales_agg sa
LEFT JOIN returns_agg ra
  ON sa.s_store_sk = ra.store_sk
 AND sa.i_category = ra.i_category
 AND sa.d_year = ra.d_year
ORDER BY sa.s_store_name, sa.i_category
