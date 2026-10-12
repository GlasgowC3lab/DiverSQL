WITH web_access AS (
    SELECT
        c.c_customer_id AS customer_id,
        d.d_year AS access_year
    FROM web_page wp
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    JOIN date_dim d ON wp.wp_access_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND wp.wp_link_count > 10
),
shipto_2000 AS (
    SELECT
        c.c_customer_id AS customer_id,
        d.d_year AS ship_year
    FROM customer c
    JOIN date_dim d ON c.c_first_shipto_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND c.c_birth_year BETWEEN 1940 AND 1970
)
SELECT
    customer_id,
    access_year
FROM web_access
EXCEPT
SELECT
    customer_id,
    ship_year AS access_year
FROM shipto_2000
ORDER BY customer_id
LIMIT 100
