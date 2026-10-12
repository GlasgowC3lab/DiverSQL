WITH
store_sales_base AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    i.i_item_id,
    i.i_product_name,
    SUM(ss.ss_quantity) AS total_qty,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, s.s_store_name, i.i_item_id, i.i_product_name
),
store_sales_agg AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_net_profit DESC) AS profit_rank
  FROM store_sales_base
),
store_returns_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    i.i_item_id,
    SUM(sr.sr_return_quantity) AS total_return_qty,
    SUM(sr.sr_net_loss) AS total_return_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, s.s_store_name, i.i_item_id
),
catalog_sales_base AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    cc.cc_name AS call_center_name,
    i.i_item_id,
    SUM(cs.cs_quantity) AS total_qty,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, cc.cc_name, i.i_item_id
),
catalog_sales_agg AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_net_profit DESC) AS profit_rank
  FROM catalog_sales_base
),
catalog_returns_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    cc.cc_name AS call_center_name,
    i.i_item_id,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    SUM(cr.cr_net_loss) AS total_return_loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, cc.cc_name, i.i_item_id
),
web_sales_base AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    wp.wp_url,
    ws.ws_web_page_sk,
    i.i_item_id,
    SUM(ws.ws_quantity) AS total_qty,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, wp.wp_url, ws.ws_web_page_sk, i.i_item_id
),
web_sales_agg AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_net_profit DESC) AS profit_rank
  FROM web_sales_base
),
web_returns_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    wp.wp_url,
    wr.wr_web_page_sk,
    i.i_item_id,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    SUM(wr.wr_net_loss) AS total_return_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, wp.wp_url, wr.wr_web_page_sk, i.i_item_id
),
combined AS (
  SELECT
    'store' AS channel,
    ss.d_year,
    ss.d_month_seq,
    ss.s_store_name AS location_name,
    ss.i_item_id,
    ss.i_product_name,
    ss.total_qty,
    ss.total_net_paid,
    ss.total_net_profit,
    COALESCE(sr.total_return_qty, 0) AS return_qty,
    COALESCE(sr.total_return_loss, 0) AS return_loss,
    ss.avg_discount,
    ss.profit_rank
  FROM store_sales_agg ss
  LEFT JOIN store_returns_agg sr
    ON ss.d_year = sr.d_year
   AND ss.d_month_seq = sr.d_month_seq
   AND ss.s_store_name = sr.s_store_name
   AND ss.i_item_id = sr.i_item_id

  UNION ALL

  SELECT
    'catalog' AS channel,
    cs.d_year,
    cs.d_month_seq,
    cs.call_center_name AS location_name,
    cs.i_item_id,
    NULL AS i_product_name,
    cs.total_qty,
    cs.total_net_paid,
    cs.total_net_profit,
    COALESCE(cr.total_return_qty, 0) AS return_qty,
    COALESCE(cr.total_return_loss, 0) AS return_loss,
    cs.avg_discount,
    cs.profit_rank
  FROM catalog_sales_agg cs
  LEFT JOIN catalog_returns_agg cr
    ON cs.d_year = cr.d_year
   AND cs.d_month_seq = cr.d_month_seq
   AND cs.call_center_name = cr.call_center_name
   AND cs.i_item_id = cr.i_item_id

  UNION ALL

  SELECT
    'web' AS channel,
    ws.d_year,
    ws.d_month_seq,
    ws.wp_url AS location_name,
    ws.i_item_id,
    NULL AS i_product_name,
    ws.total_qty,
    ws.total_net_paid,
    ws.total_net_profit,
    COALESCE(wr.total_return_qty, 0) AS return_qty,
    COALESCE(wr.total_return_loss, 0) AS return_loss,
    ws.avg_discount,
    ws.profit_rank
  FROM web_sales_agg ws
  LEFT JOIN web_returns_agg wr
    ON ws.d_year = wr.d_year
   AND ws.d_month_seq = wr.d_month_seq
   AND ws.i_item_id = wr.i_item_id
   AND ws.ws_web_page_sk = wr.wr_web_page_sk
)
SELECT
  channel,
  d_year,
  d_month_seq,
  location_name,
  i_item_id,
  i_product_name,
  total_qty,
  total_net_paid,
  total_net_profit,
  return_qty,
  return_loss,
  CASE WHEN total_qty > 0 THEN return_qty * 1.0 / total_qty ELSE NULL END AS return_rate,
  total_net_paid - return_loss AS net_sales_after_returns,
  avg_discount,
  profit_rank
FROM combined
WHERE d_year = 2001
ORDER BY channel, net_sales_after_returns DESC
LIMIT 100
