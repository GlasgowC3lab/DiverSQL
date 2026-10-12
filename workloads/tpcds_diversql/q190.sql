WITH combined AS (
    SELECT
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        wp.wp_url AS url,
        dd.d_date AS creation_date,
        wp.wp_type AS page_type,
        'auto_N' AS src
    FROM web_page wp
    JOIN date_dim dd
        ON wp.wp_creation_date_sk = dd.d_date_sk
    JOIN customer c
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE wp.wp_autogen_flag = 'N'
      AND dd.d_current_quarter = 'Y'
      AND c.c_preferred_cust_flag = 'Y'
      AND dd.d_date BETWEEN DATE '2000-01-01' AND DATE '2002-12-31'

    UNION ALL

    SELECT
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        wp.wp_url AS url,
        dd.d_date AS creation_date,
        wp.wp_type AS page_type,
        'auto_Y' AS src
    FROM web_page wp
    JOIN date_dim dd
        ON wp.wp_creation_date_sk = dd.d_date_sk
    JOIN customer c
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE wp.wp_autogen_flag = 'Y'
      AND dd.d_current_quarter = 'N'
      AND c.c_preferred_cust_flag = 'N'
      AND dd.d_date BETWEEN DATE '1999-01-01' AND DATE '2001-12-31'
)
SELECT
    ROW_NUMBER() OVER (ORDER BY creation_date DESC, src) AS rn,
    first_name,
    last_name,
    url,
    creation_date,
    page_type,
    src
FROM combined
ORDER BY rn
LIMIT 100
