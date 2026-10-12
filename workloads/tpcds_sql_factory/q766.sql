WITH cc_q AS (
    SELECT
        cc_state AS state,
        od.d_year AS year,
        od.d_quarter_name AS quarter,
        cc_tax_percentage AS tax_pct,
        cc_employees AS employees,
        cc_sq_ft AS sq_ft
    FROM call_center
    LEFT JOIN date_dim od ON call_center.cc_open_date_sk = od.d_date_sk
    WHERE cc_country = 'US'
),
store_q AS (
    SELECT
        s_state AS state,
        cd.d_year AS year,
        cd.d_quarter_name AS quarter,
        s_tax_percentage AS tax_pct,
        s_number_employees AS employees,
        s_floor_space AS sq_ft
    FROM store
    LEFT JOIN date_dim cd ON store.s_closed_date_sk = cd.d_date_sk
    WHERE s_country = 'US'
),
web_q AS (
    SELECT
        web_state AS state,
        od.d_year AS year,
        od.d_quarter_name AS quarter,
        web_tax_percentage AS tax_pct,
        0 AS employees,
        0 AS sq_ft
    FROM web_site
    LEFT JOIN date_dim od ON web_site.web_open_date_sk = od.d_date_sk
    WHERE web_country = 'US'
),
combined AS (
    SELECT * FROM cc_q
    UNION ALL
    SELECT * FROM store_q
    UNION ALL
    SELECT * FROM web_q
),
agg AS (
    SELECT
        state,
        year,
        quarter,
        AVG(tax_pct) AS avg_tax_pct,
        SUM(employees) AS total_employees,
        SUM(sq_ft) AS total_sq_ft,
        COUNT(*) AS record_cnt
    FROM combined
    GROUP BY state, year, quarter
)
SELECT
    state,
    year,
    quarter,
    avg_tax_pct,
    total_employees,
    total_sq_ft,
    record_cnt,
    total_employees / NULLIF(total_sq_ft, 0) AS employee_density,
    ROW_NUMBER() OVER (PARTITION BY state ORDER BY avg_tax_pct DESC) AS tax_rank_state,
    MAX(avg_tax_pct) OVER (PARTITION BY year) AS max_tax_year
FROM agg
WHERE total_sq_ft > 0
ORDER BY state, year, quarter
