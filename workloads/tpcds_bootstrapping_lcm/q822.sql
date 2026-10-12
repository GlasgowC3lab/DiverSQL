SELECT
    p.p_promo_id,
    p.p_promo_name,
    p.p_cost,
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_start.d_date AS promo_start_date,
    d_end.d_date   AS promo_end_date,
    date_diff('day', d_start.d_date, d_end.d_date) AS promo_duration_days,
    wp.wp_url,
    wp.wp_type,
    d_access.d_date AS page_access_date,
    date_diff('day', d_start.d_date, d_access.d_date) AS page_lifespan_days,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY p.p_cost DESC) AS promo_rank_by_cost
FROM promotion p
JOIN item i
  ON p.p_item_sk = i.i_item_sk
JOIN date_dim d_start
  ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
  ON p.p_end_date_sk = d_end.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_start.d_date_sk
JOIN web_page wp
  ON wp.wp_creation_date_sk = d_start.d_date_sk
JOIN date_dim d_access
  ON wp.wp_access_date_sk = d_access.d_date_sk
ORDER BY promo_rank_by_cost, p.p_cost DESC
LIMIT 100
