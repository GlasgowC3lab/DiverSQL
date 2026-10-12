SELECT d.d_year,
       i.i_category,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       COUNT(*) AS order_count
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
WHERE d.d_year = 2001
GROUP BY d.d_year, i.i_category
ORDER BY total_sales DESC
LIMIT 20
