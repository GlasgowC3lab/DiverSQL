SELECT
    s.s_store_id,
    s.s_city,
    d_store.d_year AS store_closed_year,
    cd.cd_gender,
    CASE 
        WHEN cd.cd_purchase_estimate < 1000 THEN 'Low'
        WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
        ELSE 'High'
    END AS purchase_estimate_bucket,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
    SUM(wp.wp_char_count) AS total_characters,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    MIN(d_access.d_date) AS earliest_access_date,
    MAX(d_access.d_date) AS latest_access_date,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    MIN(d_ship.d_date) AS earliest_ship_date,
    MAX(d_sales.d_date) AS latest_sales_date,
    AVG(date_diff('day', d_ship.d_date, d_sales.d_date)) AS avg_days_between_ship_and_sales,
    SUM(CASE WHEN d_review.d_year = d_store.d_year THEN 1 ELSE 0 END) AS reviews_in_closed_year
FROM
    store s
    INNER JOIN date_dim d_store
        ON s.s_closed_date_sk = d_store.d_date_sk
    INNER JOIN web_page wp
        ON wp.wp_creation_date_sk = d_store.d_date_sk
    INNER JOIN customer c
        ON wp.wp_customer_sk = c.c_customer_sk
    INNER JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    INNER JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    INNER JOIN date_dim d_ship
        ON c.c_first_shipto_date_sk = d_ship.d_date_sk
    INNER JOIN date_dim d_sales
        ON c.c_first_sales_date_sk = d_sales.d_date_sk
    INNER JOIN date_dim d_review
        ON c.c_last_review_date = d_review.d_date_sk
WHERE
    s.s_state = 'CA'
GROUP BY
    s.s_store_id,
    s.s_city,
    d_store.d_year,
    cd.cd_gender,
    CASE 
        WHEN cd.cd_purchase_estimate < 1000 THEN 'Low'
        WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
        ELSE 'High'
    END
HAVING
    COUNT(DISTINCT wp.wp_web_page_id) > 5
ORDER BY
    s.s_store_id,
    d_store.d_year,
    cd.cd_gender
