WITH ws_dates AS (
  SELECT
    ws.web_site_id,
    ws.web_country,
    d_open.d_date AS open_date,
    d_close.d_date AS close_date,
    d_open.d_year AS open_year,
    d_open.d_month_seq AS open_month_seq,
    d_close.d_year AS close_year,
    d_close.d_month_seq AS close_month_seq
  FROM web_site ws
  JOIN date_dim d_open ON ws.web_open_date_sk = d_open.d_date_sk
  JOIN date_dim d_close ON ws.web_close_date_sk = d_close.d_date_sk
)
SELECT
  cp.cp_department,
  ws.web_country,
  COUNT(DISTINCT cp.cp_catalog_page_sk) AS catalog_pages,
  AVG(cp.cp_catalog_page_number) AS avg_page_number,
  COUNT(DISTINCT c.c_customer_sk) AS customers,
  MIN(d_start.d_date) AS earliest_start_date,
  MAX(d_end.d_date) AS latest_end_date
FROM catalog_page cp
JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end   ON cp.cp_end_date_sk   = d_end.d_date_sk
JOIN ws_dates ws ON d_start.d_date <= ws.close_date
                 AND d_end.d_date   >= ws.open_date
CROSS JOIN customer c
JOIN date_dim d_ship ON c.c_first_shipto_date_sk = d_ship.d_date_sk
WHERE cp.cp_type = 'monthly'
  AND d_start.d_year = 2020
  AND d_ship.d_date BETWEEN ws.open_date AND ws.close_date
GROUP BY cp.cp_department, ws.web_country
HAVING COUNT(DISTINCT cp.cp_catalog_page_sk) >= 5
ORDER BY catalog_pages DESC, avg_page_number ASC
LIMIT 100
