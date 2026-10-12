SELECT
  d_year,
  d_month_seq,
  SUM(CASE WHEN sales_channel = 'store' THEN net_profit ELSE CAST(0 AS decimal(7,2)) END) AS store_net_profit,
  SUM(CASE WHEN sales_channel = 'catalog' THEN net_profit ELSE CAST(0 AS decimal(7,2)) END) AS catalog_net_profit,
  SUM(CASE WHEN sales_channel = 'web' THEN net_profit ELSE CAST(0 AS decimal(7,2)) END) AS web_net_profit,
  SUM(return_loss) AS total_return_loss
FROM (
  SELECT
    d.d_year,
    d.d_month_seq,
    cs.cs_net_profit AS net_profit,
    CAST(0 AS decimal(7,2)) AS return_loss,
    'catalog' AS sales_channel
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk

  UNION ALL

  SELECT
    d.d_year,
    d.d_month_seq,
    ss.ss_net_profit AS net_profit,
    CAST(0 AS decimal(7,2)) AS return_loss,
    'store' AS sales_channel
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk

  UNION ALL

  SELECT
    d.d_year,
    d.d_month_seq,
    ws.ws_net_profit AS net_profit,
    CAST(0 AS decimal(7,2)) AS return_loss,
    'web' AS sales_channel
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk

  UNION ALL

  SELECT
    d.d_year,
    d.d_month_seq,
    CAST(0 AS decimal(7,2)) AS net_profit,
    sr.sr_net_loss AS return_loss,
    'store' AS sales_channel
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk

  UNION ALL

  SELECT
    d.d_year,
    d.d_month_seq,
    CAST(0 AS decimal(7,2)) AS net_profit,
    cr.cr_net_loss AS return_loss,
    'catalog' AS sales_channel
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk

  UNION ALL

  SELECT
    d.d_year,
    d.d_month_seq,
    CAST(0 AS decimal(7,2)) AS net_profit,
    wr.wr_net_loss AS return_loss,
    'web' AS sales_channel
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
) t
GROUP BY d_year, d_month_seq
ORDER BY d_year, d_month_seq
LIMIT 100
