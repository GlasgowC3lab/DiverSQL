SELECT d.d_year,
       w.web_site_sk,
       (SELECT MIN(ws2.ws_quantity) FROM web_sales ws2) AS sample_quantity,
       SUM(ws.ws_net_paid) AS total_net_paid,
       COUNT(*) AS order_count
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
WHERE d.d_year = 1929
  AND t.t_hour = 22
  AND w.web_state = 'CO'
  AND ws.ws_quantity > 52
GROUP BY d.d_year, w.web_site_sk
HAVING SUM(ws.ws_net_paid) > 1824.57
