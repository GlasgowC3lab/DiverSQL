SELECT d.d_year,
       sum(ws.ws_ext_sales_price) AS total_sales,
       sum(ws.ws_net_profit) AS total_profit,
       count(*) AS sales_count
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1998 AND 2000
GROUP BY d.d_year
ORDER BY d.d_year
