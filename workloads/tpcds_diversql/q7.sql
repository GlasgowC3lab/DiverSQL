WITH home_sales AS (
   SELECT
      ws.ws_sold_date_sk,
      wp.wp_type,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_net_profit) AS total_profit
   FROM web_sales ws
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE wp.wp_type = 'home'
     AND ws.ws_ext_ship_cost > 1000
   GROUP BY ROLLUP (ws.ws_sold_date_sk, wp.wp_type)
),
product_sales AS (
   SELECT
      ws.ws_sold_date_sk,
      wp.wp_type,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_net_profit) AS total_profit
   FROM web_sales ws
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE wp.wp_type = 'product'
     AND ws.ws_ext_ship_cost > 2000
   GROUP BY ROLLUP (ws.ws_sold_date_sk, wp.wp_type)
),
combined AS (
   SELECT * FROM home_sales
   UNION ALL
   SELECT * FROM product_sales
)
SELECT
   combined.ws_sold_date_sk,
   combined.wp_type,
   combined.total_sales,
   combined.total_profit,
   ROW_NUMBER() OVER (PARTITION BY combined.wp_type ORDER BY combined.total_sales DESC) AS sales_rank
FROM combined
ORDER BY combined.wp_type, combined.ws_sold_date_sk
