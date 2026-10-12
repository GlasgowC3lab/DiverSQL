WITH catalog_agg AS (
    SELECT d.d_year AS year,
           'catalog' AS source,
           cp.cp_department AS category,
           SUM(cs.cs_net_profit) AS total_profit
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND cp.cp_department IS NOT NULL
    GROUP BY d.d_year, cp.cp_department
),
web_agg AS (
    SELECT d.d_year AS year,
           'web' AS source,
           wp.wp_type AS category,
           SUM(ws.ws_net_profit) AS total_profit
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND wp.wp_type IS NOT NULL
    GROUP BY d.d_year, wp.wp_type
)
SELECT year,
       source,
       category,
       total_profit
FROM catalog_agg
UNION
SELECT year,
       source,
       category,
       total_profit
FROM web_agg
ORDER BY year, source, total_profit DESC
