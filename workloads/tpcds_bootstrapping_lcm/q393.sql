SELECT
    d1.d_date AS store_closed_date,
    d1.d_year AS store_closed_year,
    d1.d_month_seq AS store_closed_month_seq,
    d1.d_day_name AS store_closed_day_name,
    s.s_store_id,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    s.s_floor_space,
    ws.web_site_id,
    ws.web_name,
    ws.web_city AS site_city,
    ws.web_state AS site_state,
    ws.web_tax_percentage,
    d2.d_date AS site_close_date,
    d2.d_year AS site_close_year,
    DATE_DIFF('day', d1.d_date, d2.d_date) AS site_operational_days,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY d2.d_date DESC) AS site_close_rank,
    COUNT(*) OVER (PARTITION BY s.s_store_id) AS sites_per_store
FROM store s
JOIN date_dim d1
    ON s.s_closed_date_sk = d1.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d1.d_date_sk
JOIN date_dim d2
    ON ws.web_close_date_sk = d2.d_date_sk
WHERE s.s_floor_space > 5000
  AND ws.web_tax_percentage > 0
ORDER BY d1.d_year DESC, s.s_store_id, site_close_rank
LIMIT 200
