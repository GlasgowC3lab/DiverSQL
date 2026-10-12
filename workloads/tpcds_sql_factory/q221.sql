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
        CASE WHEN date_diff('day', d_ship.d_date, d_review.d_date) > 365 THEN 1 ELSE 0 END AS churn_flag
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN date_dim d_ship ON c.c_first_shipto_date_sk = d_ship.d_date_sk
    JOIN date_dim d_review ON c.c_last_review_date = d_review.d_date_sk
    LEFT JOIN web_site ws ON c.c_first_shipto_date_sk BETWEEN ws.web_open_date_sk AND ws.web_close_date_sk
),
country_stats AS (
    SELECT
        cr.c_birth_country,
        COALESCE(cr.web_name, 'No Site') AS web_name,
        COUNT(*) AS total_customers,
        SUM(cr.churn_flag) AS churned_customers,
        AVG(cr.days_to_review) AS avg_days_to_review,
        CASE WHEN COUNT(*) = 0 THEN 0 ELSE SUM(cr.churn_flag) * 1.0 / COUNT(*) END AS churn_rate
    FROM cust_reviews cr
    GROUP BY cr.c_birth_country, cr.web_name
    HAVING COUNT(*) >= 10
)
SELECT
    c.c_birth_country,
    c.web_name,
    c.total_customers,
    c.churned_customers,
    c.avg_days_to_review,
    ROUND(100.0 * c.churn_rate, 2) AS churn_rate_pct,
    DENSE_RANK() OVER (ORDER BY c.churn_rate DESC) AS churn_rate_rank,
    LAG(ROUND(100.0 * c.churn_rate, 2)) OVER (ORDER BY c.churn_rate DESC) AS previous_country_churn_rate,
    SUM(ROUND(100.0 * c.churn_rate, 2)) OVER (ORDER BY c.churn_rate DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_churn_rate_pct
FROM country_stats c
ORDER BY churn_rate_pct DESC
LIMIT 20
