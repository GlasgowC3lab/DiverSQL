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
        CASE WHEN d_ship.d_month_seq = d_review.d_month_seq THEN 1 ELSE 0 END AS same_month_flag
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN date_dim d_ship ON c.c_first_shipto_date_sk = d_ship.d_date_sk
    JOIN date_dim d_review ON c.c_last_review_date = d_review.d_date_sk
    LEFT JOIN web_site ws ON c.c_first_shipto_date_sk BETWEEN ws.web_open_date_sk AND ws.web_close_date_sk
    WHERE d_ship.d_year = d_review.d_year
),
country_stats AS (
    SELECT
        cr.c_birth_country,
        COALESCE(cr.web_name, 'No Site') AS web_name,
        COUNT(*) AS total_customers,
        SUM(cr.same_month_flag) AS same_month_reviews,
        AVG(cr.days_to_review) AS avg_days_to_review
    FROM cust_reviews cr
    GROUP BY cr.c_birth_country, cr.web_name
)
SELECT
    c.c_birth_country,
    c.web_name,
    c.total_customers,
    c.same_month_reviews,
    ROUND(100.0 * c.same_month_reviews / NULLIF(c.total_customers,0), 2) AS same_month_pct,
    DENSE_RANK() OVER (ORDER BY c.same_month_reviews DESC) AS same_month_rank,
    MAX(c.avg_days_to_review) OVER (PARTITION BY c.c_birth_country) AS max_avg_days_country
FROM country_stats c
ORDER BY same_month_pct DESC
LIMIT 25
