WITH promo_start AS (
    SELECT
        p.p_promo_id,
        d.d_year AS start_year,
        p.p_promo_name,
        p.p_discount_active,
        p.p_start_date_sk
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    WHERE p.p_channel_dmail = 'Y'
      AND d.d_year BETWEEN 2001 AND 2003
),
promo_end AS (
    SELECT
        p.p_promo_id,
        d.d_year AS end_year,
        p.p_promo_name,
        p.p_discount_active,
        p.p_end_date_sk
    FROM promotion p
    JOIN date_dim d ON p.p_end_date_sk = d.d_date_sk
    WHERE p.p_channel_email = 'N'
      AND d.d_year BETWEEN 2001 AND 2003
),
promo_intersect AS (
    SELECT
        p_start.p_promo_id,
        p_start.start_year,
        p_start.p_promo_name,
        CASE WHEN p_start.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS status,
        (SELECT COUNT(*) FROM web_site ws WHERE ws.web_open_date_sk = p_start.p_start_date_sk) AS related_count
    FROM promo_start p_start
    INTERSECT
    SELECT
        p_end.p_promo_id,
        p_end.end_year,
        p_end.p_promo_name,
        CASE WHEN p_end.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END,
        (SELECT COUNT(*) FROM web_site ws WHERE ws.web_open_date_sk = p_end.p_end_date_sk)
    FROM promo_end p_end
),
web_page_sel AS (
    SELECT
        wp.wp_web_page_id AS entity_id,
        d.d_year AS start_year,
        wp.wp_url AS description,
        CASE WHEN wp.wp_max_ad_count > 2 THEN 'High' ELSE 'Low' END AS status,
        (SELECT COUNT(*) FROM promotion pr WHERE pr.p_start_date_sk = wp.wp_creation_date_sk) AS related_count
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE wp.wp_link_count > 10
      AND EXISTS (
          SELECT 1 FROM web_site ws
          WHERE ws.web_open_date_sk = wp.wp_creation_date_sk
            AND ws.web_state = 'TN'
      )
)
SELECT
    'Promotion' AS entity_type,
    pi.p_promo_id AS entity_id,
    pi.start_year,
    pi.p_promo_name AS description,
    pi.status,
    pi.related_count
FROM promo_intersect pi
UNION
SELECT
    'WebPage' AS entity_type,
    wp.entity_id,
    wp.start_year,
    wp.description,
    wp.status,
    wp.related_count
FROM web_page_sel wp
ORDER BY entity_type, entity_id
LIMIT 100
