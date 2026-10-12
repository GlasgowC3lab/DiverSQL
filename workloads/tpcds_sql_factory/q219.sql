WITH sales_cohort AS (
    SELECT
        c.c_customer_id,
        hd.hd_vehicle_count,
        d_sales.d_year,
        d_sales.d_moy,
        d_sales.d_quarter_seq,
        d_sales.d_date AS sales_date
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN date_dim d_sales ON c.c_first_sales_date_sk = d_sales.d_date_sk
),
cohort_agg AS (
    SELECT
        d_year,
        d_moy,
        d_quarter_seq,
        COUNT(DISTINCT c_customer_id) AS customers_in_cohort,
        SUM(hd_vehicle_count) AS total_vehicle_count
    FROM sales_cohort
    GROUP BY d_year, d_moy, d_quarter_seq
)
SELECT
    concat(CAST(d_year AS VARCHAR), '-', LPAD(CAST(d_moy AS VARCHAR), 2, '0')) AS cohort_month,
    d_quarter_seq AS cohort_quarter,
    customers_in_cohort,
    total_vehicle_count,
    LAG(total_vehicle_count) OVER (ORDER BY d_year, d_moy) AS prev_month_vehicle_total,
    CASE
        WHEN LAG(total_vehicle_count) OVER (ORDER BY d_year, d_moy) = 0 THEN NULL
        ELSE (total_vehicle_count - LAG(total_vehicle_count) OVER (ORDER BY d_year, d_moy)) * 1.0 /
             LAG(total_vehicle_count) OVER (ORDER BY d_year, d_moy)
    END AS month_over_month_growth,
    RANK() OVER (ORDER BY total_vehicle_count DESC) AS vehicle_count_rank
FROM cohort_agg
ORDER BY d_year, d_moy
LIMIT 24
