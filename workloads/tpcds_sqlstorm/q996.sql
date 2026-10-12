WITH consolidated_sales AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_class,
    i.i_brand,
    'Store' AS channel,
    s.s_store_name AS channel_name,
    ss.ss_sold_date_sk AS date_sk,
    ss.ss_item_sk AS item_sk,
    ss.ss_store_sk AS channel_sk,
    ss.ss_quantity AS quantity,
    ss.ss_ext_sales_price AS sales_amount,
    ss.ss_net_profit AS profit,
    CAST(NULL AS decimal(7,2)) AS loss
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  UNION ALL
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_class,
    i.i_brand,
    'Catalog' AS channel,
    cc.cc_name AS channel_name,
    cs.cs_sold_date_sk AS date_sk,
    cs.cs_item_sk AS item_sk,
    cs.cs_call_center_sk AS channel_sk,
    cs.cs_quantity AS quantity,
    cs.cs_ext_sales_price AS sales_amount,
    cs.cs_net_profit AS profit,
    CAST(NULL AS decimal(7,2)) AS loss
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  UNION ALL
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_class,
    i.i_brand,
    'Web' AS channel,
    wp.wp_url AS channel_name,
    ws.ws_sold_date_sk AS date_sk,
    ws.ws_item_sk AS item_sk,
    ws.ws_web_page_sk AS channel_sk,
    ws.ws_quantity AS quantity,
    ws.ws_ext_sales_price AS sales_amount,
    ws.ws_net_profit AS profit,
    CAST(NULL AS decimal(7,2)) AS loss
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
),
consolidated_returns AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_class,
    i.i_brand,
    'Store' AS channel,
    s.s_store_name AS channel_name,
    sr.sr_returned_date_sk AS date_sk,
    sr.sr_item_sk AS item_sk,
    sr.sr_store_sk AS channel_sk,
    -sr.sr_return_quantity AS quantity,
    -sr.sr_return_amt AS sales_amount,
    CAST(NULL AS decimal(7,2)) AS profit,
    sr.sr_net_loss AS loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  UNION ALL
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_class,
    i.i_brand,
    'Catalog' AS channel,
    cc.cc_name AS channel_name,
    cr.cr_returned_date_sk AS date_sk,
    cr.cr_item_sk AS item_sk,
    cr.cr_call_center_sk AS channel_sk,
    -cr.cr_return_quantity AS quantity,
    -cr.cr_return_amount AS sales_amount,
    CAST(NULL AS decimal(7,2)) AS profit,
    cr.cr_net_loss AS loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  UNION ALL
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_class,
    i.i_brand,
    'Web' AS channel,
    wp.wp_url AS channel_name,
    wr.wr_returned_date_sk AS date_sk,
    wr.wr_item_sk AS item_sk,
    wr.wr_web_page_sk AS channel_sk,
    -wr.wr_return_quantity AS quantity,
    -wr.wr_return_amt AS sales_amount,
    CAST(NULL AS decimal(7,2)) AS profit,
    wr.wr_net_loss AS loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
),
full_activity AS (
  SELECT * FROM consolidated_sales
  UNION ALL
  SELECT * FROM consolidated_returns
),
agg AS (
  SELECT
    d_year,
    d_month_seq,
    i_category,
    i_class,
    i_brand,
    channel,
    channel_name,
    SUM(sales_amount) AS total_sales,
    SUM(profit) AS total_profit,
    SUM(loss) AS total_loss,
    SUM(quantity) AS total_qty,
    COUNT(*) AS txn_count
  FROM full_activity
  GROUP BY
    d_year,
    d_month_seq,
    i_category,
    i_class,
    i_brand,
    channel,
    channel_name
),
ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_profit DESC) AS profit_rank,
    AVG(total_sales) OVER (PARTITION BY i_category ORDER BY d_year, d_month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_sales_3m
  FROM agg
)
SELECT
  d_year,
  d_month_seq,
  i_category,
  i_class,
  i_brand,
  channel,
  channel_name,
  total_sales,
  total_profit,
  total_loss,
  total_qty,
  txn_count,
  profit_rank,
  moving_avg_sales_3m
FROM ranked
WHERE profit_rank <= 10
ORDER BY d_year, d_month_seq, profit_rank
