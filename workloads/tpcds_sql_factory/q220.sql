WITH base AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_country,
        c.c_preferred_cust_flag,
        ws.web_name,
        hd.hd_vehicle_count,
        d_sales.d_year,
        c.c_birth_year,
        (hd.hd_vehicle_count *
            CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 2 ELSE 1 END) AS vehicle_score,
        CASE
            WHEN (d_sales.d_year - c.c_birth_year) < 20 THEN 'Teen'
            WHEN (d_sales.d_year - c.c_birth_year) BETWEEN 20 AND 35 THEN 'Young Adult'
            WHEN (d_sales.d_year - c.c_birth_year) BETWEEN 36 AND 55 THEN 'Adult'
            ELSE 'Senior'
        END AS age_group
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN date_dim d_sales ON c.c_first_sales_date_sk = d_sales.d_date_sk
    JOIN web_site ws ON c.c_first_shipto_date_sk BETWEEN ws.web_open_date_sk AND ws.web_close_date_sk
    JOIN date_dim d_open ON ws.web_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_close ON ws.web_close_date_sk = d_close.d_date_sk
    WHERE c.c_preferred_cust_flag IS NOT NULL
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    c_birth_country,
    age_group,
    web_name,
    vehicle_score,
    RANK() OVER (PARTITION BY age_group, c_birth_country ORDER BY vehicle_score DESC) AS rank_within_country_age,
    DENSE_RANK() OVER (ORDER BY vehicle_score DESC) AS global_dense_rank,
    SUM(vehicle_score) OVER (PARTITION BY web_name) AS total_vehicle_score_per_site
FROM base
ORDER BY global_dense_rank
LIMIT 100
