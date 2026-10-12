WITH sr_agg AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_store_sk,
        COUNT(*) AS total_returns,
        SUM(sr.sr_net_loss) AS total_net_loss,
        MIN(dr_ret.d_date) AS first_return_date,
        MAX(dr_ret.d_date) AS last_return_date
    FROM store_returns sr
    JOIN date_dim dr_ret
        ON sr.sr_returned_date_sk = dr_ret.d_date_sk
    GROUP BY sr.sr_customer_sk, sr.sr_store_sk
),
wp_agg AS (
    SELECT
        wp.wp_customer_sk,
        COUNT(DISTINCT wp.wp_web_page_id) AS web_pages_created,
        COUNT(DISTINCT wp.wp_web_page_id) AS web_pages_accessed,
        MAX(dr_wp_access.d_date) AS last_page_access_date
    FROM web_page wp
    JOIN date_dim dr_wp_creation
        ON wp.wp_creation_date_sk = dr_wp_creation.d_date_sk
    JOIN date_dim dr_wp_access
        ON wp.wp_access_date_sk = dr_wp_access.d_date_sk
    GROUP BY wp.wp_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_id,
    s.s_store_name,
    sr.total_returns,
    sr.total_net_loss,
    sr.first_return_date,
    sr.last_return_date,
    dr_cust_ship.d_date AS first_ship_date,
    dr_cust_sales.d_date AS first_sales_date,
    dr_last_review.d_date AS last_review_date,
    dr_store_closed.d_date AS store_closed_date,
    COALESCE(wp.web_pages_created, 0) AS web_pages_created,
    COALESCE(wp.web_pages_accessed, 0) AS web_pages_accessed,
    wp.last_page_access_date
FROM sr_agg sr
JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim dr_cust_ship
    ON c.c_first_shipto_date_sk = dr_cust_ship.d_date_sk
JOIN date_dim dr_cust_sales
    ON c.c_first_sales_date_sk = dr_cust_sales.d_date_sk
JOIN date_dim dr_last_review
    ON c.c_last_review_date = dr_last_review.d_date_sk
JOIN date_dim dr_store_closed
    ON s.s_closed_date_sk = dr_store_closed.d_date_sk
LEFT JOIN wp_agg wp
    ON wp.wp_customer_sk = c.c_customer_sk
ORDER BY sr.total_net_loss DESC
LIMIT 100
