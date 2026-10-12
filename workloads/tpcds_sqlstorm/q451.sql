WITH sales AS (
  SELECT
    s.channel,
    d.d_year AS sale_year,
    d.d_month_seq AS month_seq,
    i.i_category,
    i.i_category_id,
    SUM(s.ext_sales_price) AS total_sales,
    SUM(s.ext_discount_amt) AS total_discount,
    SUM(s.net_profit) AS total_profit,
    SUM(s.quantity) AS total_quantity
  FROM (
    SELECT 'store' AS channel,
           ss_sold_date_sk AS date_sk,
           ss_item_sk AS item_sk,
           ss_quantity AS quantity,
           ss_ext_sales_price AS ext_sales_price,
           ss_ext_discount_amt AS ext_discount_amt,
           ss_net_profit AS net_profit
    FROM store_sales
    UNION ALL
    SELECT 'catalog',
           cs_sold_date_sk,
           cs_item_sk,
           cs_quantity,
           cs_ext_sales_price,
           cs_ext_discount_amt,
           cs_net_profit
    FROM catalog_sales
    UNION ALL
    SELECT 'web',
           ws_sold_date_sk,
           ws_item_sk,
           ws_quantity,
           ws_ext_sales_price,
           ws_ext_discount_amt,
           ws_net_profit
    FROM web_sales
  ) s
  JOIN date_dim d ON s.date_sk = d.d_date_sk
  JOIN item i ON s.item_sk = i.i_item_sk
  GROUP BY s.channel, d.d_year, d.d_month_seq, i.i_category, i.i_category_id
), returns AS (
  SELECT
    r.channel,
    d.d_year AS sale_year,
    d.d_month_seq AS month_seq,
    i.i_category,
    i.i_category_id,
    SUM(r.return_quantity) AS total_return_qty,
    SUM(r.net_loss) AS total_return_loss
  FROM (
    SELECT 'store' AS channel,
           sr_returned_date_sk AS date_sk,
           sr_item_sk AS item_sk,
           sr_return_quantity AS return_quantity,
           sr_net_loss AS net_loss
    FROM store_returns
    UNION ALL
    SELECT 'catalog',
           cr_returned_date_sk,
           cr_item_sk,
           cr_return_quantity,
           cr_net_loss
    FROM catalog_returns
    UNION ALL
    SELECT 'web',
           wr_returned_date_sk,
           wr_item_sk,
           wr_return_quantity,
           wr_net_loss
    FROM web_returns
  ) r
  JOIN date_dim d ON r.date_sk = d.d_date_sk
  JOIN item i ON r.item_sk = i.i_item_sk
  GROUP BY r.channel, d.d_year, d.d_month_seq, i.i_category, i.i_category_id
), combined AS (
  SELECT
    s.channel,
    s.sale_year,
    s.month_seq,
    s.i_category,
    s.i_category_id,
    s.total_sales,
    s.total_discount,
    s.total_profit,
    s.total_quantity,
    COALESCE(r.total_return_qty, 0) AS total_return_qty,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
    s.total_sales - COALESCE(r.total_return_loss, 0) AS net_sales_after_returns
  FROM sales s
  LEFT JOIN returns r
    ON s.channel = r.channel
   AND s.sale_year = r.sale_year
   AND s.month_seq = r.month_seq
   AND s.i_category_id = r.i_category_id
)
SELECT
  channel,
  sale_year,
  month_seq,
  i_category,
  total_quantity,
  total_sales,
  total_discount,
  total_profit,
  total_return_qty,
  total_return_loss,
  net_profit_after_returns,
  ROUND(100.0 * net_profit_after_returns / NULLIF(total_sales, 0), 2) AS profit_margin_pct,
  ROW_NUMBER() OVER (PARTITION BY sale_year, month_seq ORDER BY net_profit_after_returns DESC) AS profit_rank
FROM combined
WHERE sale_year = 2001
ORDER BY sale_year, month_seq, net_profit_after_returns DESC
LIMIT 100
