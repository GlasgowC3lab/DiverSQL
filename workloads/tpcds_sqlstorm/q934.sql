WITH store_sales_agg AS (
    SELECT i.i_category AS category,
           d.d_year AS year,
           SUM(ss.ss_net_profit) AS profit,
           SUM(ss.ss_net_paid) AS revenue
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY i.i_category, d.d_year
),
catalog_sales_agg AS (
    SELECT i.i_category AS category,
           d.d_year AS year,
           SUM(cs.cs_net_profit) AS profit,
           SUM(cs.cs_net_paid) AS revenue
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY i.i_category, d.d_year
),
web_sales_agg AS (
    SELECT i.i_category AS category,
           d.d_year AS year,
           SUM(ws.ws_net_profit) AS profit,
           SUM(ws.ws_net_paid) AS revenue
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY i.i_category, d.d_year
)
SELECT category,
       year,
       SUM(profit) AS total_profit,
       SUM(revenue) AS total_revenue,
       SUM(revenue) - SUM(profit) AS total_cost
FROM (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
) AS agg
GROUP BY category, year
ORDER BY total_profit DESC
LIMIT 10
