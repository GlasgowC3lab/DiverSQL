WITH sales_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    'store' AS channel,
    s.s_store_id AS location_key,
    i.i_item_id AS item_key,
    SUM(ss.ss_net_profit) AS net_profit,
    SUM(ss.ss_net_paid) AS net_paid,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_ext_sales_price) AS total_ext_sales
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, s.s_store_id, i.i_item_id

  UNION ALL

  SELECT
    d.d_year,
    d.d_month_seq,
    'catalog' AS channel,
    cp.cp_catalog_page_id AS location_key,
    i.i_item_id AS item_key,
    SUM(cs.cs_net_profit) AS net_profit,
    SUM(cs.cs_net_paid) AS net_paid,
    COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
    SUM(cs.cs_quantity) AS total_quantity,
    SUM(cs.cs_ext_sales_price) AS total_ext_sales
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, cp.cp_catalog_page_id, i.i_item_id

  UNION ALL

  SELECT
    d.d_year,
    d.d_month_seq,
    'web' AS channel,
    wp.wp_web_page_id AS location_key,
    i.i_item_id AS item_key,
    SUM(ws.ws_net_profit) AS net_profit,
    SUM(ws.ws_net_paid) AS net_paid,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_ext_sales_price) AS total_ext_sales
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, wp.wp_web_page_id, i.i_item_id
), returns_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    'store' AS channel,
    s.s_store_id AS location_key,
    i.i_item_id AS item_key,
    SUM(sr.sr_net_loss) AS net_loss,
    SUM(sr.sr_return_quantity) AS return_quantity
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, s.s_store_id, i.i_item_id

  UNION ALL

  SELECT
    d.d_year,
    d.d_month_seq,
    'catalog' AS channel,
    cp.cp_catalog_page_id AS location_key,
    i.i_item_id AS item_key,
    SUM(cr.cr_net_loss) AS net_loss,
    SUM(cr.cr_return_quantity) AS return_quantity
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, cp.cp_catalog_page_id, i.i_item_id

  UNION ALL

  SELECT
    d.d_year,
    d.d_month_seq,
    'web' AS channel,
    wp.wp_web_page_id AS location_key,
    i.i_item_id AS item_key,
    SUM(wr.wr_net_loss) AS net_loss,
    SUM(wr.wr_return_quantity) AS return_quantity
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, wp.wp_web_page_id, i.i_item_id
), combined AS (
  SELECT
    s.d_year,
    s.d_month_seq,
    s.channel,
    s.location_key,
    s.item_key,
    s.net_profit - COALESCE(r.net_loss, 0) AS net_profit_adj,
    s.net_paid,
    s.distinct_customers,
    s.total_quantity,
    s.total_ext_sales,
    COALESCE(r.return_quantity, 0) AS return_quantity
  FROM sales_agg s
  LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
    AND s.channel = r.channel
    AND s.location_key = r.location_key
    AND s.item_key = r.item_key
)
SELECT
  d_year,
  d_month_seq,
  channel,
  location_key,
  item_key,
  net_profit_adj,
  net_paid,
  distinct_customers,
  total_quantity,
  total_ext_sales,
  return_quantity,
  LAG(net_profit_adj) OVER (PARTITION BY channel, d_month_seq ORDER BY d_year) AS prior_year_net_profit,
  net_profit_adj - LAG(net_profit_adj) OVER (PARTITION BY channel, d_month_seq ORDER BY d_year) AS yoy_change,
  ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq, channel ORDER BY net_profit_adj DESC) AS profit_rank
FROM combined
WHERE d_year >= 2000
ORDER BY d_year, d_month_seq, channel, profit_rank
LIMIT 100
