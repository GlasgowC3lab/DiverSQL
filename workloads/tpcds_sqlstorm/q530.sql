WITH catalog_sales_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    'Catalog' AS channel,
    cs.cs_item_sk AS item_sk,
    i.i_product_name AS product_name,
    SUM(cs.cs_net_profit) AS gross_profit,
    SUM(cs.cs_quantity) AS total_qty,
    COUNT(*) AS order_cnt
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, d.d_month_seq, cs.cs_item_sk, i.i_product_name
), store_sales_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    'Store' AS channel,
    ss.ss_item_sk AS item_sk,
    i.i_product_name AS product_name,
    SUM(ss.ss_net_profit) AS gross_profit,
    SUM(ss.ss_quantity) AS total_qty,
    COUNT(*) AS order_cnt
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, d.d_month_seq, ss.ss_item_sk, i.i_product_name
), web_sales_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    'Web' AS channel,
    ws.ws_item_sk AS item_sk,
    i.i_product_name AS product_name,
    SUM(ws.ws_net_profit) AS gross_profit,
    SUM(ws.ws_quantity) AS total_qty,
    COUNT(*) AS order_cnt
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, d.d_month_seq, ws.ws_item_sk, i.i_product_name
), catalog_returns_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    cr.cr_item_sk AS item_sk,
    SUM(cr.cr_net_loss) AS return_loss,
    SUM(cr.cr_return_quantity) AS return_qty
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_month_seq, cr.cr_item_sk
), store_returns_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    sr.sr_item_sk AS item_sk,
    SUM(sr.sr_net_loss) AS return_loss,
    SUM(sr.sr_return_quantity) AS return_qty
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_month_seq, sr.sr_item_sk
), web_returns_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    wr.wr_item_sk AS item_sk,
    SUM(wr.wr_net_loss) AS return_loss,
    SUM(wr.wr_return_quantity) AS return_qty
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_month_seq, wr.wr_item_sk
), sales_union AS (
  SELECT * FROM catalog_sales_agg
  UNION ALL
  SELECT * FROM store_sales_agg
  UNION ALL
  SELECT * FROM web_sales_agg
), returns_union AS (
  SELECT * FROM catalog_returns_agg
  UNION ALL
  SELECT * FROM store_returns_agg
  UNION ALL
  SELECT * FROM web_returns_agg
)
SELECT
  d_year,
  d_month_seq,
  channel,
  product_name,
  gross_profit,
  total_return_loss,
  net_profit_adj,
  total_qty,
  total_return_qty,
  profit_per_unit,
  profit_rank
FROM (
  SELECT
    s.d_year,
    s.d_month_seq,
    s.channel,
    s.product_name,
    s.gross_profit,
    COALESCE(r.return_loss, 0) AS total_return_loss,
    s.gross_profit - COALESCE(r.return_loss, 0) AS net_profit_adj,
    s.total_qty,
    COALESCE(r.return_qty, 0) AS total_return_qty,
    CASE WHEN s.total_qty > 0 THEN (s.gross_profit - COALESCE(r.return_loss, 0)) / s.total_qty ELSE NULL END AS profit_per_unit,
    ROW_NUMBER() OVER (PARTITION BY s.d_year, s.d_month_seq, s.channel ORDER BY (s.gross_profit - COALESCE(r.return_loss, 0)) DESC) AS profit_rank
  FROM sales_union s
  LEFT JOIN returns_union r
    ON s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
   AND s.item_sk = r.item_sk
  WHERE s.gross_profit > 0
) t
WHERE profit_rank <= 5
ORDER BY d_year, d_month_seq, channel, profit_rank
