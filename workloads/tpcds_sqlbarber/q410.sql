SELECT ws.web_name,
       d.d_date AS open_date,
       CASE WHEN ws.web_gmt_offset > 0 THEN CONCAT('UTC+', CAST(ws.web_gmt_offset AS varchar)) ELSE CONCAT('UTC', CAST(ws.web_gmt_offset AS varchar)) END AS gmt_offset_str,
       ws.web_tax_percentage * 100 AS tax_percent,
       ws.web_gmt_offset * 24 AS offset_hours,
       CONCAT(ws.web_city, ', ', ws.web_state) AS city_state,
       CASE WHEN d.d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS day_type,
       d.d_month_seq * 12 AS months_since_1900
FROM web_site ws
JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 1931
