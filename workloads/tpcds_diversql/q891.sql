WITH sampled_cc AS (
    SELECT
        cc_call_center_sk,
        cc_call_center_id,
        cc_rec_start_date,
        cc_rec_end_date,
        cc_closed_date_sk,
        cc_open_date_sk,
        cc_name,
        cc_class,
        cc_employees,
        cc_sq_ft,
        cc_hours,
        cc_manager,
        cc_mkt_id,
        cc_mkt_class,
        cc_mkt_desc,
        cc_market_manager,
        cc_division,
        cc_division_name,
        cc_company,
        cc_company_name,
        cc_street_number,
        cc_street_name,
        cc_street_type,
        cc_suite_number,
        cc_city,
        cc_county,
        cc_state,
        cc_zip,
        cc_country,
        cc_gmt_offset,
        cc_tax_percentage
    FROM call_center
    TABLESAMPLE BERNOULLI (10)
    WHERE cc_country = 'United States'
      AND cc_employees > 20
      AND cc_gmt_offset BETWEEN -5.00 AND 5.00
      AND cc_hours LIKE '8AM-%'
      AND cc_mkt_desc LIKE '%Blue%'
),
open_dates AS (
    SELECT
        cc.cc_call_center_id AS cc_id,
        d.d_date AS open_date,
        cc.cc_employees,
        cc.cc_sq_ft,
        ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_id ORDER BY d.d_date) AS rn_open,
        RANK() OVER (ORDER BY cc.cc_employees DESC) AS emp_rank
    FROM sampled_cc cc
    JOIN date_dim d
        ON cc.cc_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND d.d_week_seq >= 1
      AND d.d_fy_quarter_seq = 2
),
closed_dates AS (
    SELECT
        cc.cc_call_center_id AS cc_id,
        d.d_date AS closed_date,
        cc.cc_tax_percentage,
        cc.cc_gmt_offset,
        DENSE_RANK() OVER (ORDER BY cc.cc_tax_percentage) AS tax_rank
    FROM sampled_cc cc
    FULL OUTER JOIN date_dim d
        ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND d.d_week_seq <= 4
      AND cc.cc_tax_percentage IS NOT NULL
),
combined AS (
    SELECT
        od.cc_id,
        od.open_date,
        od.rn_open,
        od.emp_rank,
        cd.closed_date,
        cd.tax_rank,
        lt.last_open_before AS last_open_before_current
    FROM open_dates od
    LEFT JOIN closed_dates cd
        ON od.cc_id = cd.cc_id
    LEFT JOIN LATERAL (
        SELECT MAX(d2.d_date) AS last_open_before
        FROM date_dim d2
        WHERE d2.d_date < od.open_date
          AND d2.d_year = 2002
    ) lt ON TRUE
)
SELECT
    cc_id,
    open_date,
    closed_date,
    rn_open,
    emp_rank,
    tax_rank,
    last_open_before_current,
    CASE
        WHEN emp_rank <= 5 THEN 'Top5Emp'
        ELSE 'Other'
    END AS category
FROM combined
UNION
SELECT
    cc_id,
    open_date,
    closed_date,
    rn_open,
    emp_rank,
    tax_rank,
    last_open_before_current,
    CASE
        WHEN tax_rank <= 3 THEN 'LowTax'
        ELSE 'HigherTax'
    END AS category
FROM combined
ORDER BY emp_rank
LIMIT 100
