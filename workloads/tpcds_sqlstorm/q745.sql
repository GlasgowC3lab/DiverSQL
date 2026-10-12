WITH
 catalog AS (
  SELECT
    d.d_year,
    d.d_month_seq AS month_seq,
    i.i_category,
    sum(cs.cs_ext_sales_price) AS total_sales,
    sum(cs.cs_net_profit) AS total_profit,
    avg(cs.cs_ext_discount_amt / nullif(cs.cs_ext_sales_price, 0)) AS avg_discount,
    count(*) AS num_transactions
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, d.d_month_seq, i.i_category
 ),
 store AS (
  SELECT
    d.d_year,
    d.d_month_seq AS month_seq,
    i.i_category,
    sum(ss.ss_ext_sales_price) AS total_sales,
    sum(ss.ss_net_profit) AS total_profit,
    avg(ss.ss_ext_discount_amt / nullif(ss.ss_ext_sales_price, 0)) AS avg_discount,
    count(*) AS num_transactions,
    s.s_state AS state
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, d.d_month_seq, i.i_category, s.s_state
 ),
 web AS (
  SELECT
    d.d_year,
    d.d_month_seq AS month_seq,
    i.i_category,
    sum(ws.ws_ext_sales_price) AS total_sales,
    sum(ws.ws_net_profit) AS total_profit,
    avg(ws.ws_ext_discount_amt / nullif(ws.ws_ext_sales_price, 0)) AS avg_discount,
    count(*) AS num_transactions,
    w.w_state AS state
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, d.d_month_seq, i.i_category, w.w_state
 ),
 combined AS (
  SELECT 'Catalog' AS channel, d_year, month_seq, i_category, NULL AS state, total_sales, total_profit, avg_discount, num_transactions FROM catalog
  UNION ALL
  SELECT 'Store' AS channel, d_year, month_seq, i_category, state, total_sales, total_profit, avg_discount, num_transactions FROM store
  UNION ALL
  SELECT 'Web' AS channel, d_year, month_seq, i_category, state, total_sales, total_profit, avg_discount, num_transactions FROM web
 )
SELECT
  channel,
  d_year,
  month_seq,
  i_category,
  state,
  total_sales,
  total_profit,
  avg_discount,
  num_transactions,
  profit_rank
FROM (
  SELECT
    channel,
    d_year,
    month_seq,
    i_category,
    state,
    total_sales,
    total_profit,
    avg_discount,
    num_transactions,
    rank() OVER (PARTITION BY channel, d_year, month_seq ORDER BY total_profit DESC) AS profit_rank
  FROM combined
) r
WHERE profit_rank <= 5
ORDER BY channel, d_year, month_seq, profit_rank
