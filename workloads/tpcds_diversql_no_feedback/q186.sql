WITH sales_union AS (
    SELECT d.d_year AS year,
           w.w_state AS state,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           COUNT(*) AS sales_cnt,
           'catalog' AS sales_channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, w.w_state
    HAVING SUM(cs.cs_ext_sales_price) > 100000

    UNION ALL

    SELECT d.d_year AS year,
           w.w_state AS state,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(*) AS sales_cnt,
           'web' AS sales_channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, w.w_state
    HAVING SUM(ws.ws_ext_sales_price) > 100000
)
SELECT year,
       state,
       sales_channel,
       total_sales,
       sales_cnt,
       ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn
FROM sales_union
ORDER BY total_sales DESC
LIMIT 100
