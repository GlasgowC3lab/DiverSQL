WITH web_info AS (
    SELECT
        wp.wp_web_page_id,
        wp.wp_char_count,
        d.d_year,
        d.d_month_seq,
        wp.wp_url
    FROM web_page wp
    JOIN date_dim d
      ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE regexp_like(wp.wp_url, '^https?://.*')
      AND wp.wp_url LIKE '%example%'
),
promo_info AS (
    SELECT
        p.p_promo_name,
        p.p_response_target,
        d.d_year,
        d.d_month_seq,
        regexp_extract(p.p_channel_details, '(\\w+) families') AS extracted_word
    FROM promotion p
    FULL OUTER JOIN date_dim d
      ON p.p_start_date_sk = d.d_date_sk
    WHERE regexp_like(p.p_channel_details, 'families')
      AND p.p_channel_demo = 'N'
)
SELECT
    year,
    month,
    cnt,
    source
FROM (
    SELECT
        d_year AS year,
        d_month_seq AS month,
        COUNT(*) AS cnt,
        'web' AS source
    FROM web_info
    GROUP BY d_year, d_month_seq
    UNION DISTINCT
    SELECT
        d_year AS year,
        d_month_seq AS month,
        COUNT(*) AS cnt,
        'promo' AS source
    FROM promo_info
    GROUP BY d_year, d_month_seq
) t
ORDER BY year DESC, month DESC, source
