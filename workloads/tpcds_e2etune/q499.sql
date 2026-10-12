WITH promo_details AS (
    SELECT
        p.p_promo_id,
        p.p_cost,
        p.p_discount_active,
        p.p_channel_email,
        p.p_purpose,
        d_start.d_year AS start_year,
        d_start.d_quarter_name AS start_quarter,
        d_start.d_date AS start_date,
        d_end.d_year AS end_year,
        d_end.d_quarter_name AS end_quarter,
        d_end.d_date AS end_date,
        date_diff('day', d_start.d_date, d_end.d_date) AS duration_days,
        CASE
            WHEN p.p_cost < 1000 THEN 'Low'
            WHEN p.p_cost BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS cost_bucket
    FROM promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    WHERE p.p_discount_active = 'Y'
      AND d_start.d_current_quarter = 'Y'
      AND d_start.d_year BETWEEN 2010 AND 2020
),
aggregated AS (
    SELECT
        start_year,
        start_quarter,
        p_channel_email,
        cost_bucket,
        COUNT(*) AS promo_cnt,
        SUM(p_cost) AS total_cost,
        AVG(p_cost) AS avg_cost,
        AVG(duration_days) AS avg_duration_days
    FROM promo_details
    GROUP BY start_year, start_quarter, p_channel_email, cost_bucket
    HAVING COUNT(*) >= 3
)
SELECT
    start_year,
    start_quarter,
    p_channel_email,
    cost_bucket,
    promo_cnt,
    total_cost,
    avg_cost,
    avg_duration_days,
    RANK() OVER (PARTITION BY start_year ORDER BY total_cost DESC) AS quarterly_cost_rank
FROM aggregated
ORDER BY start_year, start_quarter, total_cost DESC
LIMIT 200
