WITH
sales_agg AS (
  SELECT
    'catalog' AS channel,
    d.d_year,
    d.d_month_seq AS month_seq,
    i.i_category,
    i.i_brand,
    i.i_item_id,
    cc.cc_name AS location,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_quantity) AS total_quantity,
    COUNT(DISTINCT cs.cs_order_number) AS orders
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand, i.i_item_id, cc.cc_name
),
store_agg AS (
  SELECT
    'store' AS channel,
    d.d_year,
    d.d_month_seq AS month_seq,
    i.i_category,
    i.i_brand,
    i.i_item_id,
    s.s_store_name AS location,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_quantity) AS total_quantity,
    COUNT(DISTINCT ss.ss_ticket_number) AS orders
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand, i.i_item_id, s.s_store_name
),
web_agg AS (
  SELECT
    'web' AS channel,
    d.d_year,
    d.d_month_seq AS month_seq,
    i.i_category,
    i.i_brand,
    i.i_item_id,
    wp.wp_url AS location,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS orders
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand, i.i_item_id, wp.wp_url
),
combined AS (
  SELECT * FROM sales_agg
  UNION ALL
  SELECT * FROM store_agg
  UNION ALL
  SELECT * FROM web_agg
),
ranked AS (
  SELECT
    channel,
    d_year,
    month_seq,
    i_category,
    i_brand,
    i_item_id,
    location,
    total_net_paid,
    total_net_profit,
    total_quantity,
    orders,
    ROW_NUMBER() OVER (PARTITION BY d_year, month_seq, i_category ORDER BY total_net_profit DESC) AS profit_rank
  FROM combined
)
SELECT
  channel,
  d_year,
  month_seq,
  i_category,
  i_brand,
  i_item_id,
  location,
  total_net_paid,
  total_net_profit,
  total_quantity,
  orders,
  profit_rank
FROM ranked
WHERE profit_rank <= 10
ORDER BY d_year, month_seq, i_category, profit_rank
