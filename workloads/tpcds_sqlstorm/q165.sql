SELECT d.d_year,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       AVG(ws.ws_net_profit) AS avg_profit
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
GROUP BY d.d_year
ORDER BY d.d_year
