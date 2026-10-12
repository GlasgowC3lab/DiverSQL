WITH cc_q AS (
    SELECT
        cc_state AS state,
        od.d_year AS year,
        od.d_quarter_name AS quarter,
        cc_tax_percentage AS tax_pct,
        cc_employees AS employees,
        cc_sq_ft AS sq_ft,
        CASE WHEN cc_gmt_offset > 0 THEN 'East' ELSE 'West' END AS region
    FROM call_center
    LEFT JOIN date_dim od ON call_center.cc_open_date_sk = od.d_date_sk
    WHERE od.d_month_seq BETWEEN 1 AND 6
),
store_q AS (
    SELECT
        s_state AS state,
        cd.d_year AS year,
        cd.d_quarter_name AS quarter,
        s_tax_percentage AS tax_pct,
        s_number_employees AS employees,
        s_floor_space AS sq_ft,
        CASE WHEN s_gmt_offset > 0 THEN 'East' ELSE 'West' END AS region
    FROM store
    LEFT JOIN date_dim cd ON store.s_closed_date_sk = cd.d_date_sk
    WHERE cd.d_month_seq BETWEEN 1 AND 6
),
web_q AS (
    SELECT
        web_state AS state,
        od.d_year AS year,
        od.d_quarter_name AS quarter,
        web_tax_percentage AS tax_pct,
        0 AS employees,
        0 AS sq_ft,
        CASE WHEN web_gmt_offset > 0 THEN 'East' ELSE 'West' END AS region
    FROM web_site
    LEFT JOIN date_dim od ON web_site.web_open_date_sk = od.d_date_sk
    WHERE od.d_month_seq BETWEEN 1 AND 6
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
        region,
        year,
        quarter,
        SUM(employees) AS total_employees,
        SUM(sq_ft) AS total_sq_ft,
        AVG(tax_pct) AS avg_tax_pct
    FROM combined
    GROUP BY state, region, year, quarter
)
SELECT
    state,
    region,
    year,
    quarter,
    avg_tax_pct,
    total_employees,
    total_sq_ft,
    total_employees / NULLIF(total_sq_ft, 0) AS employee_density,
    PERCENT_RANK() OVER (PARTITION BY region ORDER BY total_employees DESC) AS emp_percent_rank,
    SUM(total_employees) OVER (PARTITION BY state) AS state_total_employees
FROM agg
WHERE total_sq_ft > 0
ORDER BY region, state, year, quarter
