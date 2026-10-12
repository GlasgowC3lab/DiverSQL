SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    d.d_day_name,
    COUNT(DISTINCT cc.cc_call_center_sk) AS call_centers_closed,
    SUM(CASE WHEN cc.cc_open_date_sk = d.d_date_sk THEN 1 ELSE 0 END) AS call_centers_opened_same_day,
    COUNT(DISTINCT s.s_store_sk) AS stores_closed,
    COUNT(DISTINCT ws.web_site_sk) AS web_sites_opened,
    SUM(CASE WHEN ws.web_close_date_sk = d.d_date_sk THEN 1 ELSE 0 END) AS web_sites_closed_same_day,
    COUNT(DISTINCT cp.cp_catalog_page_sk) AS catalog_pages_started,
    SUM(CASE WHEN cp.cp_end_date_sk = d.d_date_sk THEN 1 ELSE 0 END) AS catalog_pages_ended_same_day,
    AVG(cc.cc_tax_percentage) AS avg_call_center_tax,
    AVG(s.s_tax_percentage) AS avg_store_tax,
    AVG(ws.web_tax_percentage) AS avg_web_tax,
    SUM(cc.cc_employees) AS total_cc_employees,
    SUM(s.s_number_employees) AS total_store_employees,
    CASE
        WHEN COUNT(DISTINCT cc.cc_call_center_sk) = 0 THEN NULL
        ELSE SUM(CASE WHEN cc.cc_open_date_sk = d.d_date_sk THEN 1 ELSE 0 END) * 1.0
             / COUNT(DISTINCT cc.cc_call_center_sk)
    END AS open_to_close_ratio
FROM date_dim d
LEFT JOIN call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
LEFT JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
LEFT JOIN catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk
LEFT JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
GROUP BY
    d.d_date,
    d.d_year,
    d.d_month_seq,
    d.d_day_name
HAVING COUNT(DISTINCT cc.cc_call_center_sk) > 0
ORDER BY d.d_date
