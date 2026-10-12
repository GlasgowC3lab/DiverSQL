WITH cust_risk AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_country,
        d_last.d_date AS last_review_date,
        d_sales.d_date AS first_sales_date,
        date_diff('day', d_last.d_date, current_date) AS days_since_last_review,
        date_diff('day', d_sales.d_date, current_date) AS days_since_first_sales,
        CASE
            WHEN date_diff('day', d_last.d_date, current_date) > 1825 THEN 'High'
            WHEN date_diff('day', d_last.d_date, current_date) BETWEEN 730 AND 1825 THEN 'Medium'
            ELSE 'Low'
        END AS churn_risk,
        RANK() OVER (PARTITION BY ca.ca_country ORDER BY date_diff('day', d_last.d_date, current_date) DESC) AS country_review_rank
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN date_dim d_last ON c.c_last_review_date = d_last.d_date_sk
    LEFT JOIN date_dim d_sales ON c.c_first_sales_date_sk = d_sales.d_date_sk
    WHERE hd.hd_buy_potential = 'High'
      AND date_diff('day', d_sales.d_date, current_date) > 1825
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    ca_country,
    days_since_last_review,
    days_since_first_sales,
    churn_risk,
    country_review_rank
FROM cust_risk
ORDER BY ca_country, country_review_rank
