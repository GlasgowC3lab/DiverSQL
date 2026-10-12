SELECT
    t.c_birth_country,
    t.sales_year,
    t.customer_cnt,
    t.avg_days_ship_to_sales,
    t.review_same_year_cnt,
    t.doctor_customer_cnt,
    RANK() OVER (PARTITION BY t.c_birth_country ORDER BY t.avg_days_ship_to_sales DESC) AS rank_by_avg_days
FROM (
    SELECT
        c.c_birth_country,
        d_sales.d_year AS sales_year,
        COUNT(*) AS customer_cnt,
        AVG(date_diff('day', d_ship.d_date, d_sales.d_date)) AS avg_days_ship_to_sales,
        SUM(CASE WHEN d_review.d_year = d_sales.d_year THEN 1 ELSE 0 END) AS review_same_year_cnt,
        COUNT(DISTINCT CASE WHEN c.c_salutation = 'Dr.' THEN c.c_customer_id END) AS doctor_customer_cnt
    FROM
        customer c
    JOIN date_dim d_ship
        ON c.c_first_shipto_date_sk = d_ship.d_date_sk
    JOIN date_dim d_sales
        ON c.c_first_sales_date_sk = d_sales.d_date_sk
    LEFT JOIN date_dim d_review
        ON c.c_last_review_date = d_review.d_date_sk
    WHERE
        c.c_birth_country IS NOT NULL
        AND c.c_salutation IN ('Mr.', 'Ms.', 'Dr.')
        AND c.c_preferred_cust_flag = 'Y'
        AND d_sales.d_year BETWEEN 2015 AND 2022
    GROUP BY
        c.c_birth_country,
        d_sales.d_year
    HAVING
        COUNT(*) >= 50
) t
ORDER BY
    t.avg_days_ship_to_sales DESC,
    t.customer_cnt DESC
LIMIT 200
