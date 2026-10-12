WITH all_sales AS (
  SELECT
    cs.cs_sold_date_sk AS date_sk,
    cs.cs_item_sk AS item_sk,
    cs.cs_quantity AS quantity,
    cs.cs_net_profit AS net_profit,
    cs.cs_ext_sales_price AS ext_sales,
    'catalog' AS channel,
    cs.cs_promo_sk AS promo_sk,
    cs.cs_call_center_sk AS call_center_sk
  FROM catalog_sales cs
  UNION ALL
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_item_sk,
    ss.ss_quantity,
    ss.ss_net_profit,
    ss.ss_ext_sales_price,
    'store',
    ss.ss_promo_sk,
    NULL
  FROM store_sales ss
  UNION ALL
  SELECT
    ws.ws_sold_date_sk,
    ws.ws_item_sk,
    ws.ws_quantity,
    ws.ws_net_profit,
    ws.ws_ext_sales_price,
    'web',
    ws.ws_promo_sk,
    NULL
  FROM web_sales ws
),
all_returns AS (
  SELECT
    cr.cr_returned_date_sk AS date_sk,
    cr.cr_item_sk AS item_sk,
    cr.cr_return_quantity AS quantity,
    cr.cr_net_loss AS net_loss,
    'catalog' AS channel
  FROM catalog_returns cr
  UNION ALL
  SELECT
    sr.sr_returned_date_sk,
    sr.sr_item_sk,
    sr.sr_return_quantity,
    sr.sr_net_loss,
    'store'
  FROM store_returns sr
  UNION ALL
  SELECT
    wr.wr_returned_date_sk,
    wr.wr_item_sk,
    wr.wr_return_quantity,
    wr.wr_net_loss,
    'web'
  FROM web_returns wr
),
sales_with_dates AS (
  SELECT
    s.channel,
    i.i_item_sk,
    i.i_brand,
    i.i_category,
    d.d_year,
    d.d_quarter_seq,
    SUM(s.quantity) AS total_quantity,
    SUM(s.ext_sales) AS total_sales,
    SUM(s.net_profit) AS total_net_profit,
    SUM(COALESCE(p.p_cost, 0)) AS total_promo_cost,
    SUM(COALESCE(cc.cc_gmt_offset, 0)) AS total_call_center_offset
  FROM all_sales s
  LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
  LEFT JOIN call_center cc ON s.call_center_sk = cc.cc_call_center_sk
  JOIN item i ON s.item_sk = i.i_item_sk
  JOIN date_dim d ON s.date_sk = d.d_date_sk
  GROUP BY s.channel, i.i_item_sk, i.i_brand, i.i_category, d.d_year, d.d_quarter_seq
),
returns_agg AS (
  SELECT
    r.channel,
    i.i_item_sk,
    i.i_brand,
    i.i_category,
    d.d_year,
    d.d_quarter_seq,
    SUM(r.quantity) AS total_return_quantity,
    SUM(r.net_loss) AS total_return_loss
  FROM all_returns r
  JOIN item i ON r.item_sk = i.i_item_sk
  JOIN date_dim d ON r.date_sk = d.d_date_sk
  GROUP BY r.channel, i.i_item_sk, i.i_brand, i.i_category, d.d_year, d.d_quarter_seq
)
SELECT
  s.channel,
  s.i_brand,
  s.i_category,
  s.d_year,
  s.d_quarter_seq,
  s.total_quantity,
  s.total_sales,
  s.total_net_profit,
  s.total_promo_cost,
  s.total_call_center_offset,
  COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
  COALESCE(r.total_return_loss, 0) AS total_return_loss,
  (s.total_net_profit - COALESCE(r.total_return_loss, 0)) AS net_profit_after_returns,
  ROW_NUMBER() OVER (PARTITION BY s.channel, s.d_year ORDER BY (s.total_net_profit - COALESCE(r.total_return_loss, 0)) DESC) AS rank_by_profit
FROM sales_with_dates s
LEFT JOIN returns_agg r
  ON s.channel = r.channel
 AND s.i_item_sk = r.i_item_sk
 AND s.d_year = r.d_year
 AND s.d_quarter_seq = r.d_quarter_seq
WHERE s.d_year = 2002
ORDER BY s.channel, s.d_year, rank_by_profit
LIMIT 100
