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
        CASE WHEN hd.hd_vehicle_count >= 2 THEN 1 ELSE 0 END AS high_vehicle_flag
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN date_dim d_ship ON c.c_first_shipto_date_sk = d_ship.d_date_sk
    JOIN date_dim d_review ON c.c_last_review_date = d_review.d_date_sk
    LEFT JOIN web_site ws ON c.c_first_shipto_date_sk BETWEEN ws.web_open_date_sk AND ws.web_close_date_sk
    WHERE d_ship.d_year BETWEEN 2015 AND 2020
),
country_stats AS (
    SELECT
        cr.c_birth_country,
        COALESCE(cr.web_name, 'No Site') AS web_name,
        COUNT(*) AS total_customers,
        SUM(cr.high_vehicle_flag) AS high_vehicle_customers,
        AVG(cr.days_to_review) AS avg_days_to_review
    FROM cust_reviews cr
    GROUP BY cr.c_birth_country, cr.web_name
)
SELECT
    c.c_birth_country,
    c.web_name,
    c.total_customers,
    c.high_vehicle_customers,
    ROUND(c.avg_days_to_review, 2) AS avg_days_to_review,
    100.0 * c.high_vehicle_customers / NULLIF(c.total_customers, 0) AS high_vehicle_pct,
    RANK() OVER (ORDER BY c.high_vehicle_customers DESC) AS vehicle_rank,
    MAX(c.avg_days_to_review) OVER (PARTITION BY c.c_birth_country) AS max_avg_days_country
FROM country_stats c
ORDER BY high_vehicle_pct DESC
LIMIT 20
