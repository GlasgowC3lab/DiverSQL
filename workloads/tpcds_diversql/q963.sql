WITH created_pages AS (
    SELECT wp.wp_web_page_sk,
           wp.wp_url,
           d.d_date AS creation_date,
           wp.wp_type,
           wp.wp_link_count
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE wp.wp_type = 'order'
      AND d.d_quarter_seq = 12
      AND wp.wp_autogen_flag = 'N'
),
accessed_pages AS (
    SELECT wp.wp_web_page_sk,
           wp.wp_url,
           d.d_date AS access_date,
           wp.wp_type,
           wp.wp_link_count
    FROM web_page wp
    JOIN date_dim d ON wp.wp_access_date_sk = d.d_date_sk
    WHERE wp.wp_type = 'order'
      AND d.d_quarter_seq = 12
),
intersect_pages AS (
    SELECT wp_web_page_sk,
           wp_url,
           creation_date,
           wp_type,
           wp_link_count
    FROM created_pages
    INTERSECT
    SELECT wp_web_page_sk,
           wp_url,
           access_date AS creation_date,
           wp_type,
           wp_link_count
    FROM accessed_pages
),
exclude_pages AS (
    SELECT wp_web_page_sk
    FROM web_page
    WHERE wp_autogen_flag = 'Y'
),
union_pages AS (
    SELECT ip.wp_web_page_sk,
           ip.wp_url,
           ip.creation_date,
           ip.wp_type,
           ip.wp_link_count
    FROM intersect_pages ip
    WHERE ip.wp_web_page_sk NOT IN (SELECT wp_web_page_sk FROM exclude_pages)
    UNION
    SELECT wp.wp_web_page_sk,
           wp.wp_url,
           d.d_date AS creation_date,
           wp.wp_type,
           wp.wp_link_count
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE wp.wp_type = 'welcome'
      AND d.d_year = 2001
)
SELECT wp_web_page_sk,
       wp_url,
       creation_date,
       wp_type,
       wp_link_count
FROM union_pages
ORDER BY creation_date DESC, wp_web_page_sk
OFFSET 20 LIMIT 100
