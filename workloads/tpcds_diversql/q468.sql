WITH
  ss_agg AS (
    SELECT
      ss_sold_date_sk,
      ss_item_sk,
      SUM(ss_ext_sales_price) AS total_sales,
      SUM(ss_net_profit)       AS total_profit
    FROM store_sales
    WHERE ss_sales_price > 10.00                     -- realistic filter
      AND ss_ext_tax < 50.00                         -- realistic filter
    GROUP BY ss_sold_date_sk, ss_item_sk
  ),
  wr_agg AS (
    SELECT
      wr_returned_date_sk,
      wr_item_sk,
      wr_returning_cdemo_sk,
      SUM(wr_return_amt_inc_tax) AS total_return_amt
    FROM web_returns
    WHERE wr_return_tax > 20.00                     -- realistic filter
      AND wr_return_amt_inc_tax > 0.00               -- realistic filter
    GROUP BY wr_returned_date_sk, wr_item_sk, wr_returning_cdemo_sk
  ),
  inv_agg AS (
    SELECT
      inv_date_sk,
      inv_item_sk,
      SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0                 -- realistic filter
    GROUP BY inv_date_sk, inv_item_sk
  ),
  common_dates AS (
    SELECT ss_sold_date_sk AS d_date_sk FROM store_sales
    INTERSECT
    SELECT wr_returned_date_sk FROM web_returns
  )
SELECT
  d.d_date,
  d.d_year,
  COALESCE(SUM(ss_agg.total_sales), 0)           AS total_sales,
  COALESCE(SUM(ss_agg.total_profit), 0)          AS total_profit,
  COALESCE(SUM(wr_agg.total_return_amt), 0)      AS total_return_amt,
  COUNT(DISTINCT wr_agg.wr_returning_cdemo_sk)   AS distinct_returning_customers,
  COALESCE(SUM(inv_agg.total_on_hand), 0)        AS total_on_hand,
  COUNT(DISTINCT ss_agg.ss_item_sk)              AS distinct_items_sold,
  COUNT(DISTINCT inv_agg.inv_item_sk)            AS distinct_items_in_inventory
FROM date_dim d
RIGHT OUTER JOIN ss_agg
  ON ss_agg.ss_sold_date_sk = d.d_date_sk
FULL OUTER JOIN wr_agg
  ON wr_agg.wr_returned_date_sk = d.d_date_sk
LEFT JOIN inv_agg
  ON inv_agg.inv_date_sk = d.d_date_sk
WHERE d.d_fy_quarter_seq = 2                     -- selective predicate on dimension
  AND d.d_following_holiday = 'N'                  -- realistic predicate
  AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND d.d_date_sk IN (SELECT d_date_sk FROM common_dates)
GROUP BY d.d_date, d.d_year
ORDER BY d.d_date ASC
OFFSET 0 LIMIT 100
