WITH cust_details AS (
    SELECT
        c.c_customer_id,
        ca.ca_city,
        d_sales.d_year AS sales_year,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        CASE
            WHEN date_diff('day', d_last.d_date, current_date) > 730 THEN 'Stale'
            ELSE 'Active'
        END AS review_status
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN date_dim d_sales ON c.c_first_sales_date_sk = d_sales.d_date_sk
    LEFT JOIN date_dim d_last ON c.c_last_review_date = d_last.d_date_sk
),
city_agg AS (
    SELECT
        ca_city AS city,
        sales_year,
        COUNT(DISTINCT c_customer_id) AS total_customers,
        AVG(hd_vehicle_count) AS avg_vehicles,
        AVG(hd_dep_count) AS avg_dep,
        SUM(CASE WHEN review_status = 'Stale' THEN 1 ELSE 0 END) AS stale_customers,
        SUM(CASE WHEN review_status = 'Active' THEN 1 ELSE 0 END) AS active_customers
    FROM cust_details
    GROUP BY ca_city, sales_year
)
SELECT
    city,
    sales_year,
    total_customers,
    avg_vehicles,
    avg_dep,
    DENSE_RANK() OVER (ORDER BY avg_vehicles DESC) AS city_vehicle_rank,
    stale_customers,
    active_customers
FROM city_agg
ORDER BY city_vehicle_rank, city
