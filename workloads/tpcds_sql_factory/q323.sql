WITH cust_reviews AS (
    SELECT
        c.c_customer_id,
        c.c_birth_country,
        ws.web_name,
        d_ship.d_date AS ship_date,
        d_review.d_date AS review_date,
        hd.hd_vehicle_count,
        c.c_preferred_cust_flag,
        c.c_birth_year,
        date_diff('day', d_ship.d_date, d_review.d_date) AS days_to_review,
        CASE WHEN c.c_birth_year < 1980 THEN 1 ELSE 0 END AS senior_flag
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN date_dim d_ship ON c.c_first_shipto_date_sk = d_ship.d_date_sk
    JOIN date_dim d_review ON c.c_last_review_date = d_review.d_date_sk
    LEFT JOIN web_site ws ON c.c_first_shipto_date_sk BETWEEN ws.web_open_date_sk AND ws.web_close_date_sk
    WHERE ws.web_state = 'CA' OR ws.web_state IS NULL
),
country_stats AS (
    SELECT
        cr.c_birth_country,
        COALESCE(cr.web_name, 'No Site') AS web_name,
        COUNT(*) AS total_customers,
        SUM(cr.senior_flag) AS senior_customers,
        AVG(cr.days_to_review) AS avg_days_to_review
    FROM cust_reviews cr
    GROUP BY cr.c_birth_country, cr.web_name
    HAVING COUNT(*) >= 8
)
SELECT
    c.c_birth_country,
    c.web_name,
    c.total_customers,
    c.senior_customers,
    ROUND(100.0 * c.senior_customers / NULLIF(c.total_customers,0), 2) AS senior_pct,
    ROW_NUMBER() OVER (ORDER BY c.senior_customers DESC) AS senior_rank,
    SUM(c.total_customers) OVER (ORDER BY c.senior_customers DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_customers
FROM country_stats c
ORDER BY senior_pct DESC
LIMIT 10
