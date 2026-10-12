WITH promotion_stats AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        i.i_item_id,
        i.i_product_name,
        start_d.d_date AS promo_start_date,
        start_d.d_day_name AS start_day_name,
        start_d.d_weekend AS start_is_weekend,
        end_d.d_date AS promo_end_date,
        end_d.d_day_name AS end_day_name,
        end_d.d_weekend AS end_is_weekend,
        date_diff('day', start_d.d_date, end_d.d_date) AS promo_duration_days,
        p.p_cost,
        p.p_response_target,
        p.p_discount_active
    FROM promotion p
    INNER JOIN item i ON p.p_item_sk = i.i_item_sk
    INNER JOIN date_dim start_d ON p.p_start_date_sk = start_d.d_date_sk
    INNER JOIN date_dim end_d ON p.p_end_date_sk = end_d.d_date_sk
    WHERE p.p_discount_active = 'Y'
),
stores_closed AS (
    SELECT
        p.p_promo_id,
        COUNT(DISTINCT s.s_store_id) AS stores_closed_on_end
    FROM promotion p
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    LEFT JOIN store s ON s.s_closed_date_sk = d_end.d_date_sk
    GROUP BY p.p_promo_id
),
pages_created AS (
    SELECT
        p.p_promo_id,
        COUNT(*) AS pages_created_on_start,
        SUM(wp.wp_image_count) AS total_image_created,
        AVG(wp.wp_char_count) AS avg_char_created
    FROM promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_start.d_date_sk
    GROUP BY p.p_promo_id
),
pages_accessed AS (
    SELECT
        p.p_promo_id,
        COUNT(*) AS pages_accessed_on_end,
        SUM(wp.wp_image_count) AS total_image_accessed,
        AVG(wp.wp_char_count) AS avg_char_accessed
    FROM promotion p
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    JOIN web_page wp ON wp.wp_access_date_sk = d_end.d_date_sk
    GROUP BY p.p_promo_id
)
SELECT
    ps.p_promo_id,
    ps.p_promo_name,
    ps.i_item_id,
    ps.i_product_name,
    ps.promo_start_date,
    ps.start_day_name,
    ps.start_is_weekend,
    ps.promo_end_date,
    ps.end_day_name,
    ps.end_is_weekend,
    ps.promo_duration_days,
    ps.p_cost,
    ps.p_response_target,
    COALESCE(sc.stores_closed_on_end, 0) AS stores_closed_on_end,
    COALESCE(pc.pages_created_on_start, 0) AS pages_created_on_start,
    COALESCE(pc.total_image_created, 0) AS total_image_created,
    COALESCE(pc.avg_char_created, 0) AS avg_char_created,
    COALESCE(pa.pages_accessed_on_end, 0) AS pages_accessed_on_end,
    COALESCE(pa.total_image_accessed, 0) AS total_image_accessed,
    COALESCE(pa.avg_char_accessed, 0) AS avg_char_accessed
FROM promotion_stats ps
LEFT JOIN stores_closed sc ON ps.p_promo_id = sc.p_promo_id
LEFT JOIN pages_created pc ON ps.p_promo_id = pc.p_promo_id
LEFT JOIN pages_accessed pa ON ps.p_promo_id = pa.p_promo_id
ORDER BY ps.promo_duration_days DESC
LIMIT 10
