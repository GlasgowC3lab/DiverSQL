WITH inv_metrics AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        SUM(i.inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk, d.d_date
),
page_creation_metrics AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        SUM(wp.wp_image_count) AS total_images,
        SUM(wp.wp_char_count) AS total_chars
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk, d.d_date
),
page_access_metrics AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        SUM(wp.wp_link_count) AS total_links
    FROM web_page wp
    JOIN date_dim d ON wp.wp_access_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk, d.d_date
),
store_metrics AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        COUNT(DISTINCT s.s_store_id) AS stores_closed,
        AVG(s.s_floor_space) AS avg_store_floor_space
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk, d.d_date
),
site_metrics AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        COUNT(DISTINCT ws.web_site_id) AS sites_opened,
        COUNT(DISTINCT ws.web_site_id) FILTER (WHERE ws.web_close_date_sk = d.d_date_sk) AS sites_closed,
        AVG(ws.web_tax_percentage) AS avg_site_tax
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk, d.d_date
)
SELECT
    d.d_date,
    im.total_inventory,
    im.distinct_items,
    pcm.total_images,
    pcm.total_chars,
    pam.total_links,
    sm.stores_closed,
    sm.avg_store_floor_space,
    ssm.sites_opened,
    ssm.sites_closed,
    ssm.avg_site_tax,
    (im.total_inventory * 0.5 + pcm.total_images * 0.3 + pam.total_links * 0.2) AS composite_score,
    ROW_NUMBER() OVER (ORDER BY (im.total_inventory * 0.5 + pcm.total_images * 0.3 + pam.total_links * 0.2) DESC) AS rank
FROM date_dim d
LEFT JOIN inv_metrics im ON im.d_date_sk = d.d_date_sk
LEFT JOIN page_creation_metrics pcm ON pcm.d_date_sk = d.d_date_sk
LEFT JOIN page_access_metrics pam ON pam.d_date_sk = d.d_date_sk
LEFT JOIN store_metrics sm ON sm.d_date_sk = d.d_date_sk
LEFT JOIN site_metrics ssm ON ssm.d_date_sk = d.d_date_sk
WHERE im.total_inventory IS NOT NULL
ORDER BY composite_score DESC
LIMIT 100
