WITH cc AS (
    SELECT
        cc_market_manager AS manager,
        cc_rec_start_date AS rec_start_date,
        cc_employees AS employees,
        'Call Center' AS entity_type
    FROM call_center
),
st AS (
    SELECT
        s_market_manager AS manager,
        s_rec_start_date AS rec_start_date,
        s_number_employees AS employees,
        'Store' AS entity_type
    FROM store
),
combined AS (
    SELECT * FROM cc
    UNION ALL
    SELECT * FROM st
),
with_dates AS (
    SELECT
        c.manager,
        c.rec_start_date,
        c.employees,
        c.entity_type,
        d.d_year,
        d.d_quarter_name
    FROM combined c
    LEFT JOIN date_dim d ON c.rec_start_date = d.d_date
),
lagged AS (
    SELECT
        manager,
        entity_type,
        rec_start_date,
        employees,
        d_year,
        d_quarter_name,
        LAG(employees) OVER (PARTITION BY manager, entity_type ORDER BY rec_start_date) AS prev_employees
    FROM with_dates
),
total_emp AS (
    SELECT
        manager,
        SUM(employees) AS total_employees
    FROM lagged
    GROUP BY manager
)
SELECT
    l.manager,
    l.entity_type,
    l.rec_start_date,
    l.employees,
    l.prev_employees,
    (l.employees - l.prev_employees) AS employee_change,
    CASE
        WHEN l.prev_employees IS NULL THEN 'N/A'
        WHEN l.employees > l.prev_employees THEN 'Growth'
        WHEN l.employees = l.prev_employees THEN 'Stable'
        WHEN l.employees < l.prev_employees THEN 'Decline'
        ELSE 'Unknown'
    END AS change_category,
    RANK() OVER (ORDER BY t.total_employees DESC) AS manager_employee_rank
FROM lagged l
JOIN total_emp t ON l.manager = t.manager
WHERE l.employees IS NOT NULL
ORDER BY manager_employee_rank, l.manager, l.rec_start_date
