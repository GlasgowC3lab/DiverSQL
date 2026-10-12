WITH cp_dates AS (
    SELECT
        cp.cp_department,
        cp.cp_catalog_page_number,
        cp.cp_type,
        d_start.d_date AS start_date,
        d_end.d_date   AS end_date,
        d_start.d_year AS start_year,
        d_end.d_year   AS end_year
    FROM catalog_page cp
    JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end   ON cp.cp_end_date_sk   = d_end.d_date_sk
),
wp_dates AS (
    SELECT
        wp.wp_web_page_id,
        wp.wp_customer_sk,
        wp.wp_link_count,
        wp.wp_char_count,
        wp.wp_type,
        d_creation.d_date AS creation_date,
        d_access.d_date   AS access_date
    FROM web_page wp
    JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access   ON wp.wp_access_date_sk   = d_access.d_date_sk
),
cust_dates AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        d_shipto.d_date   AS shipto_date,
        d_sales.d_date    AS first_sales_date,
        d_last_review.d_date AS last_review_date
    FROM customer c
    JOIN date_dim d_shipto      ON c.c_first_shipto_date_sk = d_shipto.d_date_sk
    JOIN date_dim d_sales       ON c.c_first_sales_date_sk  = d_sales.d_date_sk
    JOIN date_dim d_last_review ON c.c_last_review_date    = d_last_review.d_date_sk
),
store_dates AS (
    SELECT
        s.s_store_id,
        s.s_city,
        s.s_state,
        s.s_market_id,
        s.s_floor_space,
        d_closed.d_date AS store_closed_date
    FROM store s
    JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
)
SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    s.store_closed_date,
    cp.cp_department,
    cp.cp_catalog_page_number,
    cp.start_date AS catalog_start_date,
    cp.end_date   AS catalog_end_date,
    DATE_DIFF('day', cp.start_date, cp.end_date) AS catalog_duration_days,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    SUM(wp.wp_link_count)            AS total_link_count,
    AVG(wp.wp_char_count)            AS avg_char_count,
    COUNT(DISTINCT c.c_customer_id)  AS distinct_customers,
    MIN(c.first_sales_date)          AS earliest_customer_sales_date,
    MAX(wp.access_date)              AS latest_web_page_access_date,
    (SELECT AVG(s2.s_floor_space) FROM store s2) AS avg_floor_space_all_stores,
    COUNT(*) FILTER (WHERE wp.wp_type = 'article') AS article_web_pages,
    SUM(CASE WHEN cp.cp_type = 'promo' THEN 1 ELSE 0 END) AS promo_catalog_pages,
    cp.start_year,
    cp.end_year
FROM cp_dates cp
JOIN wp_dates wp
    ON wp.creation_date BETWEEN cp.start_date AND cp.end_date
   AND wp.access_date    BETWEEN cp.start_date AND cp.end_date
JOIN cust_dates c
    ON wp.wp_customer_sk = c.c_customer_sk
CROSS JOIN store_dates s
GROUP BY
    s.s_store_id,
    s.s_city,
    s.s_state,
    s.store_closed_date,
    cp.cp_department,
    cp.cp_catalog_page_number,
    cp.start_date,
    cp.end_date,
    cp.start_year,
    cp.end_year
