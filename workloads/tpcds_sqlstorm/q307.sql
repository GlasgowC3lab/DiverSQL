WITH
sales_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    'store' AS channel,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_net_profit) AS total_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, i.i_category
  UNION ALL
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    'catalog' AS channel,
    SUM(cs.cs_quantity) AS total_quantity,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_net_profit) AS total_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, i.i_category
  UNION ALL
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    'web' AS channel,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_net_profit) AS total_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, i.i_category
),
returns_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    'store' AS channel,
    SUM(sr.sr_return_quantity) AS return_quantity,
    SUM(sr.sr_net_loss) AS return_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, i.i_category
  UNION ALL
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    'catalog' AS channel,
    SUM(cr.cr_return_quantity) AS return_quantity,
    SUM(cr.cr_net_loss) AS return_loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, i.i_category
  UNION ALL
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    'web' AS channel,
    SUM(wr.wr_return_quantity) AS return_quantity,
    SUM(wr.wr_net_loss) AS return_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT
  sa.d_year,
  sa.d_month_seq,
  sa.i_category,
  sa.channel,
  sa.total_quantity,
  COALESCE(ra.return_quantity, 0) AS return_quantity,
  CASE WHEN sa.total_quantity = 0 THEN 0 ELSE CAST(COALESCE(ra.return_quantity, 0) AS double) / sa.total_quantity END AS return_rate,
  sa.total_net_paid,
  COALESCE(ra.return_loss, 0) AS return_loss,
  (sa.total_profit - COALESCE(ra.return_loss, 0)) AS net_profit_after_returns,
  CASE WHEN sa.total_net_paid = 0 THEN 0 ELSE ROUND(sa.total_discount / sa.total_net_paid * 100, 2) END AS discount_pct,
  RANK() OVER (PARTITION BY sa.d_year, sa.d_month_seq, sa.channel ORDER BY (sa.total_profit - COALESCE(ra.return_loss, 0)) DESC) AS profit_rank
FROM sales_agg sa
LEFT JOIN returns_agg ra
  ON sa.d_year = ra.d_year
 AND sa.d_month_seq = ra.d_month_seq
 AND sa.i_category = ra.i_category
 AND sa.channel = ra.channel
WHERE sa.d_year BETWEEN 2000 AND 2002
ORDER BY sa.d_year, sa.d_month_seq, sa.channel, profit_rank
