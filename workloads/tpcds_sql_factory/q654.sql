WITH combined_sales AS (
  SELECT
    cs.cs_sold_date_sk AS date_sk,
    cs.cs_net_paid_inc_tax AS net_paid_inc_tax,
    'catalog' AS channel,
    cs.cs_item_sk AS item_sk
  FROM catalog_sales cs
  UNION ALL
  SELECT
    ws.ws_sold_date_sk AS date_sk,
    ws.ws_net_paid_inc_tax AS net_paid_inc_tax,
    'web' AS channel,
    ws.ws_item_sk AS item_sk
  FROM web_sales ws
),
sales_by_date_category AS (
  SELECT
    cs.date_sk,
    i.i_category,
    cs.channel,
    SUM(cs.net_paid_inc_tax) AS total_net_paid_inc_tax
  FROM combined_sales cs
  JOIN item i ON cs.item_sk = i.i_item_sk
  GROUP BY cs.date_sk, i.i_category, cs.channel
),
running_totals AS (
  SELECT
    date_sk,
    i_category,
    channel,
    total_net_paid_inc_tax,
    SUM(total_net_paid_inc_tax) OVER (PARTITION BY i_category ORDER BY date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_by_category
  FROM sales_by_date_category
)
SELECT
  date_sk,
  i_category,
  channel,
  total_net_paid_inc_tax,
  cumulative_by_category
FROM running_totals
ORDER BY i_category, date_sk
