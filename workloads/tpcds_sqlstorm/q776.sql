WITH
sales AS (
  SELECT cs.cs_sold_date_sk AS date_sk, cs.cs_item_sk AS item_sk,
         cs.cs_quantity AS quantity,
         cs.cs_net_paid AS net_paid,
         cs.cs_net_profit AS net_profit,
         'catalog' AS channel
  FROM catalog_sales cs
  UNION ALL
  SELECT ss.ss_sold_date_sk, ss.ss_item_sk,
         ss.ss_quantity,
         ss.ss_net_paid,
         ss.ss_net_profit,
         'store' AS channel
  FROM store_sales ss
  UNION ALL
  SELECT ws.ws_sold_date_sk, ws.ws_item_sk,
         ws.ws_quantity,
         ws.ws_net_paid,
         ws.ws_net_profit,
         'web' AS channel
  FROM web_sales ws
),
sales_enriched AS (
  SELECT s.date_sk, s.item_sk, s.quantity, s.net_paid, s.net_profit, s.channel,
         i.i_category AS category,
         i.i_brand AS brand
  FROM sales s
  JOIN item i ON s.item_sk = i.i_item_sk
),
sales_agg AS (
  SELECT d.d_year,
         d.d_quarter_seq,
         d.d_month_seq,
         s.channel,
         s.category,
         s.brand,
         SUM(s.quantity) AS total_quantity,
         SUM(s.net_paid) AS total_net_paid,
         SUM(s.net_profit) AS total_net_profit
  FROM sales_enriched s
  JOIN date_dim d ON s.date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_quarter_seq, d.d_month_seq, s.channel, s.category, s.brand
),
returns AS (
  SELECT cr.cr_returned_date_sk AS date_sk, cr.cr_item_sk AS item_sk,
         cr.cr_return_quantity AS quantity,
         cr.cr_net_loss AS net_loss,
         'catalog' AS channel
  FROM catalog_returns cr
  UNION ALL
  SELECT sr.sr_returned_date_sk, sr.sr_item_sk,
         sr.sr_return_quantity,
         sr.sr_net_loss,
         'store' AS channel
  FROM store_returns sr
  UNION ALL
  SELECT wr.wr_returned_date_sk, wr.wr_item_sk,
         wr.wr_return_quantity,
         wr.wr_net_loss,
         'web' AS channel
  FROM web_returns wr
),
returns_enriched AS (
  SELECT r.date_sk, r.item_sk, r.quantity, r.net_loss, r.channel,
         i.i_category AS category,
         i.i_brand AS brand
  FROM returns r
  JOIN item i ON r.item_sk = i.i_item_sk
),
returns_agg AS (
  SELECT d.d_year,
         d.d_quarter_seq,
         d.d_month_seq,
         r.channel,
         r.category,
         r.brand,
         SUM(r.quantity) AS total_return_quantity,
         SUM(r.net_loss) AS total_return_net_loss
  FROM returns_enriched r
  JOIN date_dim d ON r.date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_quarter_seq, d.d_month_seq, r.channel, r.category, r.brand
),
joined AS (
  SELECT
    sa.d_year,
    sa.d_quarter_seq,
    sa.channel,
    sa.category,
    sa.brand,
    sa.total_quantity,
    sa.total_net_paid,
    sa.total_net_profit,
    COALESCE(ra.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(ra.total_return_net_loss, 0) AS total_return_net_loss,
    (sa.total_net_profit - COALESCE(ra.total_return_net_loss, 0)) AS net_profit_after_returns
  FROM sales_agg sa
  LEFT JOIN returns_agg ra
    ON sa.d_year = ra.d_year
   AND sa.d_quarter_seq = ra.d_quarter_seq
   AND sa.channel = ra.channel
   AND sa.category = ra.category
   AND sa.brand = ra.brand
),
ranked AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY d_year, d_quarter_seq, channel ORDER BY net_profit_after_returns DESC) AS rank
  FROM joined
)
SELECT
  d_year,
  d_quarter_seq,
  channel,
  category,
  brand,
  total_quantity,
  total_net_paid,
  total_net_profit,
  total_return_quantity,
  total_return_net_loss,
  net_profit_after_returns
FROM ranked
WHERE rank <= 5
ORDER BY d_year, d_quarter_seq, channel, rank
