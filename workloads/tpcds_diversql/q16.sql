WITH sold_sales AS (
    SELECT dd.d_fy_year,
           dd.d_dow,
           SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales,
           SUM(COALESCE(ws.ws_net_profit, 0))       AS total_profit,
           'sold'                                     AS sales_category
    FROM web_sales ws
    RIGHT OUTER JOIN date_dim dd
        ON ws.ws_sold_date_sk = dd.d_date_sk
       AND ws.ws_web_site_sk = 45
    WHERE dd.d_fy_year BETWEEN 1905 AND 1915
      AND dd.d_dow = 2
    GROUP BY dd.d_fy_year, dd.d_dow
),
shipped_sales AS (
    SELECT dd.d_fy_year,
           dd.d_dow,
           SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales,
           SUM(COALESCE(ws.ws_net_profit, 0))       AS total_profit,
           'shipped'                                AS sales_category
    FROM web_sales ws
    RIGHT OUTER JOIN date_dim dd
        ON ws.ws_ship_date_sk = dd.d_date_sk
       AND ws.ws_web_site_sk = 37
    WHERE dd.d_fy_year BETWEEN 1905 AND 1915
      AND dd.d_dow = 3
    GROUP BY dd.d_fy_year, dd.d_dow
)
SELECT d_fy_year,
       d_dow,
       total_sales,
       total_profit,
       sales_category
FROM sold_sales
UNION ALL
SELECT d_fy_year,
       d_dow,
       total_sales,
       total_profit,
       sales_category
FROM shipped_sales
ORDER BY d_fy_year, sales_category
LIMIT 100
