SELECT
    ws.web_name,
    ws.web_city,
    dd.d_date AS open_date
FROM web_site ws
JOIN date_dim dd
  ON ws.web_open_date_sk = dd.d_date_sk
WHERE dd.d_year = 2020
  AND dd.d_weekend = 'N'
  AND ws.web_state = 'CA'
LIMIT 100
