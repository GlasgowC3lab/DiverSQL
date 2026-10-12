WITH sales AS (
  SELECT cs_sold_date_sk AS date_sk,
         cs_item_sk AS item_sk,
         cs_call_center_sk AS call_center_sk,
         NULL AS store_sk,
         NULL AS web_page_sk,
         'catalog' AS channel,
         cs_quantity AS quantity,
         cs_net_paid AS net_paid,
         cs_net_profit AS net_profit
  FROM catalog_sales
  UNION ALL
  SELECT ss_sold_date_sk,
         ss_item_sk,
         NULL,
         ss_store_sk,
         NULL,
         'store',
         ss_quantity,
         ss_net_paid,
         ss_net_profit
  FROM store_sales
  UNION ALL
  SELECT ws_sold_date_sk,
         ws_item_sk,
         NULL,
         NULL,
         ws_web_page_sk,
         'web',
         ws_quantity,
         ws_net_paid,
         ws_net_profit
  FROM web_sales
),
returns AS (
  SELECT cr_returned_date_sk AS date_sk,
         cr_item_sk AS item_sk,
         cr_call_center_sk AS call_center_sk,
         NULL AS store_sk,
         NULL AS web_page_sk,
         'catalog' AS channel,
         cr_return_quantity AS quantity,
         cr_refunded_cash AS refunded_cash,
         cr_net_loss AS net_loss
  FROM catalog_returns
  UNION ALL
  SELECT sr_returned_date_sk,
         sr_item_sk,
         NULL,
         sr_store_sk,
         NULL,
         'store',
         sr_return_quantity,
         sr_refunded_cash,
         sr_net_loss
  FROM store_returns
  UNION ALL
  SELECT wr_returned_date_sk,
         wr_item_sk,
         NULL,
         NULL,
         wr_web_page_sk,
         'web',
         wr_return_quantity,
         wr_refunded_cash,
         wr_net_loss
  FROM web_returns
),
sales_agg AS (
  SELECT d.d_year AS sales_year,
         s.channel,
         i.i_category,
         i.i_class,
         SUM(s.quantity) AS total_quantity,
         SUM(s.net_paid) AS total_net_paid,
         SUM(s.net_profit) AS total_net_profit
  FROM sales s
  JOIN date_dim d ON s.date_sk = d.d_date_sk
  JOIN item i ON s.item_sk = i.i_item_sk
  GROUP BY d.d_year, s.channel, i.i_category, i.i_class
),
returns_agg AS (
  SELECT d.d_year AS sales_year,
         r.channel,
         i.i_category,
         i.i_class,
         SUM(r.quantity) AS total_return_quantity,
         SUM(r.refunded_cash) AS total_refunded_cash,
         SUM(r.net_loss) AS total_net_loss
  FROM returns r
  JOIN date_dim d ON r.date_sk = d.d_date_sk
  JOIN item i ON r.item_sk = i.i_item_sk
  GROUP BY d.d_year, r.channel, i.i_category, i.i_class
),
combined AS (
  SELECT s.sales_year,
         s.channel,
         s.i_category,
         s.i_class,
         s.total_quantity,
         s.total_net_paid,
         s.total_net_profit,
         COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
         COALESCE(r.total_refunded_cash, 0) AS total_refunded_cash,
         COALESCE(r.total_net_loss, 0) AS total_net_loss,
         (s.total_net_profit - COALESCE(r.total_net_loss, 0)) AS net_profit_after_returns,
         (s.total_net_paid - COALESCE(r.total_refunded_cash, 0)) AS net_paid_after_returns
  FROM sales_agg s
  LEFT JOIN returns_agg r
    ON s.sales_year = r.sales_year
    AND s.channel = r.channel
    AND s.i_category = r.i_category
    AND s.i_class = r.i_class
),
ranked AS (
  SELECT sales_year,
         channel,
         i_category,
         i_class,
         total_quantity,
         net_profit_after_returns,
         SUM(net_profit_after_returns) OVER (PARTITION BY channel ORDER BY sales_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
         LAG(net_profit_after_returns) OVER (PARTITION BY channel ORDER BY sales_year) AS previous_year_profit,
         CASE
           WHEN LAG(net_profit_after_returns) OVER (PARTITION BY channel ORDER BY sales_year) IS NULL THEN NULL
           ELSE (net_profit_after_returns - LAG(net_profit_after_returns) OVER (PARTITION BY channel ORDER BY sales_year)) / NULLIF(LAG(net_profit_after_returns) OVER (PARTITION BY channel ORDER BY sales_year), 0)
         END AS yoy_growth,
         ROW_NUMBER() OVER (PARTITION BY sales_year, channel ORDER BY net_profit_after_returns DESC) AS profit_rank
  FROM combined
)
SELECT sales_year,
       channel,
       i_category,
       i_class,
       total_quantity,
       net_profit_after_returns,
       cumulative_profit,
       yoy_growth,
       profit_rank
FROM ranked
WHERE profit_rank <= 5
ORDER BY sales_year, channel, profit_rank
