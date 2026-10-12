WITH wp_creation AS (
    SELECT wp_creation_date_sk AS date_sk,
           COUNT(DISTINCT wp_web_page_id) AS created_pages
    FROM web_page
    GROUP BY wp_creation_date_sk
),
wp_access AS (
    SELECT wp_access_date_sk AS date_sk,
           COUNT(DISTINCT wp_web_page_id) AS accessed_pages
    FROM web_page
    GROUP BY wp_access_date_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_class,
    p.p_promo_id,
    p.p_promo_name,
    d_start.d_date AS promo_start_date,
    d_end.d_date AS promo_end_date,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    s.s_city,
    d_end.d_date AS store_closed_date,
    COALESCE(wc.created_pages, 0) AS pages_created_on_start,
    COALESCE(wa.accessed_pages, 0) AS pages_accessed_on_end,
    p.p_cost,
    i.i_wholesale_cost,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY p.p_cost DESC) AS promo_rank_by_cost
FROM promotion p
JOIN item i ON p.p_item_sk = i.i_item_sk
JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_end.d_date_sk
LEFT JOIN wp_creation wc ON wc.date_sk = d_start.d_date_sk
LEFT JOIN wp_access wa ON wa.date_sk = d_end.d_date_sk
WHERE p.p_discount_active = 'Y'
ORDER BY i.i_item_id, promo_rank_by_cost
