WITH sales AS (
    SELECT cs_sold_date_sk AS date_sk, cs_item_sk AS item_sk, cs_net_profit AS net_profit FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk, ss_item_sk, ss_net_profit FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk, ws_item_sk, ws_net_profit FROM web_sales
),
returns AS (
    SELECT cr_returned_date_sk AS date_sk, cr_item_sk AS item_sk, cr_net_loss AS net_loss FROM catalog_returns
    UNION ALL
    SELECT sr_returned_date_sk, sr_item_sk, sr_net_loss FROM store_returns
    UNION ALL
    SELECT wr_returned_date_sk, wr_item_sk, wr_net_loss FROM web_returns
),
sales_agg AS (
    SELECT d.d_year AS year, i.i_category AS category,
           sum(s.net_profit) AS total_profit,
           count(*) AS sales_cnt
    FROM sales s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_year, i.i_category
),
returns_agg AS (
    SELECT d.d_year AS year, i.i_category AS category,
           sum(r.net_loss) AS total_loss,
           count(*) AS returns_cnt
    FROM returns r
    JOIN date_dim d ON r.date_sk = d.d_date_sk
    JOIN item i ON r.item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_year, i.i_category
)
SELECT s.year,
       s.category,
       s.total_profit,
       coalesce(r.total_loss, 0) AS total_loss,
       s.sales_cnt,
       coalesce(r.returns_cnt, 0) AS returns_cnt,
       s.total_profit - coalesce(r.total_loss, 0) AS net_profit_after_returns,
       case when s.sales_cnt > 0 then s.total_profit / s.sales_cnt else null end AS avg_profit_per_sale,
       case when r.returns_cnt > 0 then r.total_loss / r.returns_cnt else null end AS avg_loss_per_return
FROM sales_agg s
LEFT JOIN returns_agg r ON s.year = r.year AND s.category = r.category
ORDER BY net_profit_after_returns DESC
LIMIT 100
