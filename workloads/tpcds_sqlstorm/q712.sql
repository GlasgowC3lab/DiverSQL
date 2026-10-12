WITH sales_agg AS (
    SELECT d.d_year AS year,
           i.i_category AS category,
           SUM(s.quantity) AS total_quantity_sold,
           SUM(s.net_profit) AS total_net_profit
    FROM (
        SELECT cs_sold_date_sk AS date_sk, cs_item_sk AS item_sk, cs_quantity AS quantity, cs_net_profit AS net_profit FROM catalog_sales
        UNION ALL
        SELECT ss_sold_date_sk, ss_item_sk, ss_quantity, ss_net_profit FROM store_sales
        UNION ALL
        SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_net_profit FROM web_sales
    ) s
    JOIN item i ON s.item_sk = i.i_item_sk
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    GROUP BY d.d_year, i.i_category
),
returns_agg AS (
    SELECT d.d_year AS year,
           i.i_category AS category,
           SUM(r.quantity) AS total_quantity_returned,
           SUM(r.net_loss) AS total_return_loss
    FROM (
        SELECT cr_returned_date_sk AS date_sk, cr_item_sk AS item_sk, cr_return_quantity AS quantity, cr_net_loss AS net_loss FROM catalog_returns
        UNION ALL
        SELECT sr_returned_date_sk, sr_item_sk, sr_return_quantity, sr_net_loss FROM store_returns
        UNION ALL
        SELECT wr_returned_date_sk, wr_item_sk, wr_return_quantity, wr_net_loss FROM web_returns
    ) r
    JOIN item i ON r.item_sk = i.i_item_sk
    JOIN date_dim d ON r.date_sk = d.d_date_sk
    GROUP BY d.d_year, i.i_category
)
SELECT s.year,
       s.category,
       s.total_quantity_sold,
       s.total_net_profit,
       COALESCE(r.total_return_loss, 0) AS total_return_loss,
       s.total_net_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
       CASE
           WHEN LAG(s.total_net_profit - COALESCE(r.total_return_loss, 0)) OVER (PARTITION BY s.category ORDER BY s.year) IS NULL THEN NULL
           ELSE ((s.total_net_profit - COALESCE(r.total_return_loss, 0))
                - LAG(s.total_net_profit - COALESCE(r.total_return_loss, 0)) OVER (PARTITION BY s.category ORDER BY s.year))
                / NULLIF(LAG(s.total_net_profit - COALESCE(r.total_return_loss, 0)) OVER (PARTITION BY s.category ORDER BY s.year), 0) * 100
       END AS yoy_profit_change_pct,
       ROW_NUMBER() OVER (PARTITION BY s.year ORDER BY (s.total_net_profit - COALESCE(r.total_return_loss, 0)) DESC) AS rank_in_year
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.year = r.year AND s.category = r.category
WHERE s.total_net_profit - COALESCE(r.total_return_loss, 0) > 0
ORDER BY s.year, rank_in_year
