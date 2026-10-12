WITH store_sales_agg AS (
  SELECT
    i.i_category AS category,
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    'store' AS channel,
    COALESCE(SUM(ss.ss_net_profit), 0) AS gross_profit,
    COALESCE(SUM(sr.sr_net_loss), 0) AS return_loss,
    COALESCE(SUM(ss.ss_net_profit), 0) - COALESCE(SUM(sr.sr_net_loss), 0) AS net_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
   AND ss.ss_item_sk = sr.sr_item_sk
  GROUP BY i.i_category, d.d_year, d.d_month_seq
),
catalog_sales_agg AS (
  SELECT
    i.i_category AS category,
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    'catalog' AS channel,
    COALESCE(SUM(cs.cs_net_profit), 0) AS gross_profit,
    COALESCE(SUM(cr.cr_net_loss), 0) AS return_loss,
    COALESCE(SUM(cs.cs_net_profit), 0) - COALESCE(SUM(cr.cr_net_loss), 0) AS net_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cs.cs_item_sk = cr.cr_item_sk
  GROUP BY i.i_category, d.d_year, d.d_month_seq
),
web_sales_agg AS (
  SELECT
    i.i_category AS category,
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    'web' AS channel,
    COALESCE(SUM(ws.ws_net_profit), 0) AS gross_profit,
    COALESCE(SUM(wr.wr_net_loss), 0) AS return_loss,
    COALESCE(SUM(ws.ws_net_profit), 0) - COALESCE(SUM(wr.wr_net_loss), 0) AS net_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
  GROUP BY i.i_category, d.d_year, d.d_month_seq
),
combined_sales AS (
  SELECT * FROM store_sales_agg
  UNION ALL
  SELECT * FROM catalog_sales_agg
  UNION ALL
  SELECT * FROM web_sales_agg
),
ranked_sales AS (
  SELECT
    category,
    channel,
    year,
    month_seq,
    net_profit,
    ROW_NUMBER() OVER (PARTITION BY year, channel ORDER BY net_profit DESC) AS rank_year_channel,
    SUM(net_profit) OVER (PARTITION BY category, channel ORDER BY year, month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_profit
  FROM combined_sales
)
SELECT
  category,
  channel,
  year,
  month_seq,
  net_profit,
  cumulative_net_profit,
  rank_year_channel
FROM ranked_sales
WHERE rank_year_channel <= 5
ORDER BY year, channel, rank_year_channel
