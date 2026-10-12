SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_store.d_date AS store_closed_date,
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    p.p_promo_id,
    p.p_promo_name,
    d_start.d_date AS promo_start_date,
    d_end.d_date AS promo_end_date,
    p.p_cost,
    i.i_current_price,
    i.i_wholesale_cost,
    (i.i_current_price - i.i_wholesale_cost) AS gross_margin,
    COUNT(DISTINCT wp_creation.wp_web_page_id) AS pages_created_on_start,
    COUNT(DISTINCT wp_access.wp_web_page_id) AS pages_accessed_on_end,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY p.p_cost DESC) AS promo_rank_by_cost
FROM store s
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
CROSS JOIN promotion p
JOIN item i
    ON p.p_item_sk = i.i_item_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
LEFT JOIN web_page wp_creation
    ON wp_creation.wp_creation_date_sk = d_start.d_date_sk
LEFT JOIN web_page wp_access
    ON wp_access.wp_access_date_sk = d_end.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_store.d_date,
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    p.p_promo_id,
    p.p_promo_name,
    d_start.d_date,
    d_end.d_date,
    p.p_cost,
    i.i_current_price,
    i.i_wholesale_cost
ORDER BY
    s.s_store_id,
    promo_rank_by_cost
