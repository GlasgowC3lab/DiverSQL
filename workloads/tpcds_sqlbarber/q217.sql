SELECT d.d_year, w.web_state, SUM(ws.ws_net_paid) AS total_net_paid, COUNT(ws.ws_order_number) AS order_count
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
WHERE d.d_year = 1918 AND w.web_country = 'United States'
GROUP BY d.d_year, w.web_state
