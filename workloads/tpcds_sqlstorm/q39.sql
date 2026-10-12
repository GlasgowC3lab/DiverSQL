WITH
store_agg AS (
  SELECT
    d.d_year AS year,
    ca.ca_state AS state,
    i.i_category AS category,
    sum(ss.ss_net_paid) AS total_sales,
    sum(ss.ss_net_profit) AS total_profit,
    sum(ss.ss_quantity) AS total_quantity,
    sum(ss.ss_ext_discount_amt) AS total_discount_amount,
    avg(ss.ss_ext_discount_amt / nullif(ss.ss_ext_sales_price, 0)) AS avg_discount_ratio,
    'store' AS channel
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  GROUP BY d.d_year, ca.ca_state, i.i_category
),
web_agg AS (
  SELECT
    d.d_year AS year,
    ca.ca_state AS state,
    i.i_category AS category,
    sum(ws.ws_net_paid) AS total_sales,
    sum(ws.ws_net_profit) AS total_profit,
    sum(ws.ws_quantity) AS total_quantity,
    sum(ws.ws_ext_discount_amt) AS total_discount_amount,
    avg(ws.ws_ext_discount_amt / nullif(ws.ws_ext_sales_price, 0)) AS avg_discount_ratio,
    'web' AS channel
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  GROUP BY d.d_year, ca.ca_state, i.i_category
),
catalog_agg AS (
  SELECT
    d.d_year AS year,
    cc.cc_state AS state,
    i.i_category AS category,
    sum(cs.cs_net_paid) AS total_sales,
    sum(cs.cs_net_profit) AS total_profit,
    sum(cs.cs_quantity) AS total_quantity,
    sum(cs.cs_ext_discount_amt) AS total_discount_amount,
    avg(cs.cs_ext_discount_amt / nullif(cs.cs_ext_sales_price, 0)) AS avg_discount_ratio,
    'catalog' AS channel
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  GROUP BY d.d_year, cc.cc_state, i.i_category
),
combined AS (
  SELECT * FROM store_agg
  UNION ALL
  SELECT * FROM web_agg
  UNION ALL
  SELECT * FROM catalog_agg
),
channel_rank AS (
  SELECT
    year,
    state,
    category,
    channel,
    total_sales,
    total_profit,
    total_quantity,
    total_discount_amount,
    avg_discount_ratio,
    row_number() OVER (PARTITION BY year, state ORDER BY total_sales DESC) AS sales_rank,
    sum(total_sales) OVER (PARTITION BY year, state) AS state_year_total_sales
  FROM combined
)
SELECT
  year,
  state,
  category,
  channel,
  total_sales,
  total_profit,
  total_quantity,
  total_discount_amount,
  avg_discount_ratio,
  sales_rank,
  round(total_sales / nullif(state_year_total_sales, 0) * 100, 2) AS sales_share_pct
FROM channel_rank
WHERE sales_rank <= 3
ORDER BY year, state, sales_rank
