WITH sales_union AS (
    SELECT d.d_year AS year, i.i_category AS category, ss.ss_net_profit AS profit, ss.ss_net_paid AS revenue
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year, i.i_category, cs.cs_net_profit, cs.cs_net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year, i.i_category, ws.ws_net_profit, ws.ws_net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
sales_agg AS (
    SELECT year, category,
           SUM(profit) AS sales_profit,
           SUM(revenue) AS sales_revenue
    FROM sales_union
    GROUP BY year, category
),
returns_union AS (
    SELECT d.d_year AS year, i.i_category AS category, cr.cr_net_loss AS loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year, i.i_category, sr.sr_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year, i.i_category, wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
),
returns_agg AS (
    SELECT year, category,
           SUM(loss) AS returns_loss
    FROM returns_union
    GROUP BY year, category
),
combined AS (
    SELECT s.year,
           s.category,
           s.sales_profit,
           s.sales_revenue,
           COALESCE(r.returns_loss, 0) AS returns_loss,
           s.sales_profit - COALESCE(r.returns_loss, 0) AS net_profit
    FROM sales_agg s
    LEFT JOIN returns_agg r
      ON s.year = r.year AND s.category = r.category
)
SELECT year,
       category,
       sales_profit,
       sales_revenue,
       returns_loss,
       net_profit,
       RANK() OVER (PARTITION BY year ORDER BY net_profit DESC) AS profit_rank,
       LAG(net_profit) OVER (PARTITION BY category ORDER BY year) AS prior_year_profit,
       CASE WHEN LAG(net_profit) OVER (PARTITION BY category ORDER BY year) IS NULL THEN NULL
            ELSE (net_profit - LAG(net_profit) OVER (PARTITION BY category ORDER BY year)) / NULLIF(LAG(net_profit) OVER (PARTITION BY category ORDER BY year), 0)
       END AS yoy_growth
FROM combined
ORDER BY year, profit_rank
