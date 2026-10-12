SELECT
    cp.cp_type,
    cp.cp_department,
    s.s_state,
    s.s_city,
    ws.web_city,
    d_start.d_year,
    d_start.d_month_seq,
    date_diff('day', MIN(d_start.d_date), MAX(d_end.d_date)) AS catalog_page_duration_days,
    date_diff('day', MIN(d_start.d_date), MAX(d_ws_close.d_date)) AS web_site_open_to_close_days,
    COUNT(DISTINCT cp.cp_catalog_page_sk) AS catalog_page_cnt,
    COUNT(DISTINCT c.c_customer_sk) AS customer_cnt,
    SUM(s.s_floor_space) AS total_floor_space,
    AVG(s.s_number_employees) AS avg_employees,
    MAX(d_end.d_date) AS max_end_date,
    MIN(d_start.d_date) AS min_start_date,
    COUNT(*) FILTER (WHERE d_ship.d_month_seq = d_start.d_month_seq) AS same_month_shipto_cnt
FROM catalog_page cp
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_end.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_start.d_date_sk
JOIN date_dim d_ws_close
    ON ws.web_close_date_sk = d_ws_close.d_date_sk
JOIN customer c
    ON c.c_first_sales_date_sk = d_start.d_date_sk
JOIN date_dim d_ship
    ON c.c_first_shipto_date_sk = d_ship.d_date_sk
WHERE d_start.d_year >= 2015
  AND s.s_number_employees > 0
GROUP BY
    cp.cp_type,
    cp.cp_department,
    s.s_state,
    s.s_city,
    ws.web_city,
    d_start.d_year,
    d_start.d_month_seq
HAVING COUNT(DISTINCT cp.cp_catalog_page_sk) > 5
   AND SUM(s.s_floor_space) > 10000
ORDER BY catalog_page_cnt DESC
LIMIT 100
