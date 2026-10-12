WITH open_cc AS (
    SELECT d.d_year,
           SUM(cc.cc_employees) AS total_employees,
           COUNT(DISTINCT cc.cc_call_center_id) AS cc_count
    FROM call_center cc
    JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
    WHERE cc.cc_class = 'large'
      AND cc.cc_gmt_offset BETWEEN -8.00 AND -5.00
      AND d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year
),
start_cp AS (
    SELECT d.d_year,
           COUNT(DISTINCT cp.cp_catalog_page_id) AS catalog_page_cnt,
           AVG(cp.cp_catalog_page_number) AS avg_catalog_page_number
    FROM catalog_page cp
    JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year
),
access_wp AS (
    SELECT d.d_year,
           COUNT(DISTINCT wp.wp_web_page_id) AS web_page_cnt,
           AVG(wp.wp_char_count) AS avg_web_page_char_count
    FROM web_page wp
    JOIN date_dim d ON wp.wp_access_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year
)
SELECT oc.d_year,
       oc.total_employees,
       oc.cc_count,
       cp.catalog_page_cnt,
       cp.avg_catalog_page_number,
       wp.web_page_cnt,
       wp.avg_web_page_char_count,
       (oc.total_employees / NULLIF(cp.catalog_page_cnt, 0)) AS employees_per_catalog_page,
       (oc.total_employees / NULLIF(wp.web_page_cnt, 0)) AS employees_per_web_page,
       ROW_NUMBER() OVER (ORDER BY oc.total_employees DESC) AS employee_rank
FROM open_cc oc
LEFT JOIN start_cp cp ON oc.d_year = cp.d_year
LEFT JOIN access_wp wp ON oc.d_year = wp.d_year
ORDER BY oc.d_year
