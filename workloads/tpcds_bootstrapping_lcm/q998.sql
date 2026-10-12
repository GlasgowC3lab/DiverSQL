SELECT
    d_ret.d_year AS return_year,
    CASE WHEN d_ret.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END AS half_year,
    s.s_division_name AS division,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT wp.wp_type) AS distinct_page_types,
    AVG(date_diff('day', d_page.d_date, d_ret.d_date)) AS avg_days_page_to_return,
    COUNT(DISTINCT ws.web_site_id) AS distinct_web_sites,
    MIN(d_store.d_year) AS store_close_year,
    MIN(d_open.d_year) AS site_open_year
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_page
    ON wp.wp_creation_date_sk = d_page.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_store
    ON d_store.d_date_sk = s.s_closed_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_ret.d_date_sk
JOIN date_dim d_open
    ON d_open.d_date_sk = ws.web_open_date_sk
GROUP BY
    d_ret.d_year,
    CASE WHEN d_ret.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END,
    s.s_division_name
ORDER BY
    d_ret.d_year,
    half_year,
    s.s_division_name
LIMIT 100
