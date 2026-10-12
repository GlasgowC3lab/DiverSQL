WITH
  agg_sales AS (
    SELECT
      ss_item_sk,
      ss_store_sk,
      SUM(ss_net_paid) AS total_net_paid,
      SUM(ss_quantity) AS total_quantity,
      COUNT(DISTINCT ss_ticket_number) AS cnt_tickets
    FROM store_sales TABLESAMPLE BERNOULLI (10)
    WHERE ss_quantity >= 2
      AND ss_net_paid > 0
      AND ss_ext_discount_amt < 50
      AND ss_sold_time_sk BETWEEN 1000 AND 2000
      AND ss_store_sk IN (1, 2, 3)
      AND ss_item_sk IN (100, 200)
    GROUP BY ss_item_sk, ss_store_sk
  ),
  agg_returns AS (
    SELECT
      cr_item_sk,
      SUM(cr_return_amount) AS total_return_amount,
      COUNT(*) AS cnt_returns
    FROM catalog_returns
    WHERE cr_return_tax > 10
      AND cr_fee < 70
      AND cr_return_quantity >= 1
      AND cr_return_amount > 0
      AND cr_return_ship_cost < 20
      AND cr_reason_sk IN (1, 2, 3)
    GROUP BY cr_item_sk
  )
SELECT
  volume_category,
  SUM(total_net_paid) AS sum_net_paid,
  SUM(total_quantity) AS sum_quantity,
  SUM(cnt_tickets) AS sum_tickets,
  SUM(total_return_amount) AS sum_return_amount,
  SUM(cnt_returns) AS sum_return_cnt,
  COUNT(*) AS row_cnt
FROM (
  SELECT
    i.i_item_id,
    s.s_store_name,
    agg_sales.total_net_paid,
    agg_sales.total_quantity,
    agg_sales.cnt_tickets,
    COALESCE(agg_returns.total_return_amount, 0) AS total_return_amount,
    COALESCE(agg_returns.cnt_returns, 0) AS cnt_returns,
    CASE WHEN agg_sales.total_quantity > 100 THEN 'High Volume' ELSE 'Normal Volume' END AS volume_category
  FROM agg_sales
  JOIN item i ON agg_sales.ss_item_sk = i.i_item_sk
  JOIN store s ON agg_sales.ss_store_sk = s.s_store_sk
  LEFT JOIN agg_returns ON agg_sales.ss_item_sk = agg_returns.cr_item_sk
  WHERE i.i_brand = 'esecallyable'
    AND s.s_manager = 'Scott Smith'
    AND i.i_rec_start_date = DATE '1999-10-28'
    AND i.i_rec_end_date = DATE '2000-10-26'
    AND s.s_tax_percentage < 5.00
    AND s.s_gmt_offset BETWEEN -5.00 AND 0.00

  UNION DISTINCT

  SELECT
    i.i_item_id,
    s.s_store_name,
    agg_sales.total_net_paid,
    agg_sales.total_quantity,
    agg_sales.cnt_tickets,
    COALESCE(agg_returns.total_return_amount, 0) AS total_return_amount,
    COALESCE(agg_returns.cnt_returns, 0) AS cnt_returns,
    CASE WHEN agg_sales.total_quantity > 100 THEN 'High Volume' ELSE 'Normal Volume' END AS volume_category
  FROM agg_sales
  JOIN item i ON agg_sales.ss_item_sk = i.i_item_sk
  JOIN store s ON agg_sales.ss_store_sk = s.s_store_sk
  LEFT JOIN agg_returns ON agg_sales.ss_item_sk = agg_returns.cr_item_sk
  WHERE i.i_brand = 'barableable'
    AND s.s_manager = 'Leroy Walker'
    AND i.i_rec_start_date = DATE '2000-10-27'
    AND i.i_rec_end_date = DATE '2001-10-26'
    AND s.s_tax_percentage >= 5.00
    AND s.s_gmt_offset BETWEEN 0.00 AND 5.00
) AS unioned
GROUP BY volume_category
ORDER BY sum_net_paid DESC
OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY
