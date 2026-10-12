SELECT ws.web_name,
       dd.d_day_name,
       ws.web_tax_percentage
FROM web_site ws
JOIN date_dim dd ON ws.web_open_date_sk = dd.d_date_sk
WHERE dd.d_dow = 5
  AND ws.web_tax_percentage >= 0.10
ORDER BY ws.web_name
