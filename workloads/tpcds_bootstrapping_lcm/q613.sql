WITH
    promo_agg AS (
        SELECT
            p.p_start_date_sk AS date_sk,
            i.i_category,
            i.i_brand,
            COUNT(DISTINCT p.p_promo_id) AS num_promotions,
            SUM(p.p_cost) AS total_promo_cost,
            AVG(i.i_current_price) AS avg_item_price,
            SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) AS active_discount_cost
        FROM promotion p
        JOIN item i ON p.p_item_sk = i.i_item_sk
        GROUP BY p.p_start_date_sk, i.i_category, i.i_brand
    ),
    store_agg AS (
        SELECT
            s.s_closed_date_sk AS date_sk,
            s.s_state,
            COUNT(*) AS num_stores,
            SUM(s.s_tax_percentage) AS total_tax_percentage
        FROM store s
        GROUP BY s.s_closed_date_sk, s.s_state
    ),
    web_creation_agg AS (
        SELECT
            wp.wp_creation_date_sk AS date_sk,
            COUNT(DISTINCT wp.wp_web_page_id) AS num_creation_pages
        FROM web_page wp
        GROUP BY wp.wp_creation_date_sk
    ),
    web_access_agg AS (
        SELECT
            wp.wp_access_date_sk AS date_sk,
            COUNT(DISTINCT wp.wp_web_page_id) AS num_access_pages
        FROM web_page wp
        GROUP BY wp.wp_access_date_sk
    )
SELECT
    d.d_year,
    d.d_quarter_seq,
    s_agg.s_state,
    p_agg.i_category,
    p_agg.i_brand,
    p_agg.num_promotions,
    p_agg.total_promo_cost,
    p_agg.avg_item_price,
    p_agg.active_discount_cost,
    s_agg.num_stores,
    s_agg.total_tax_percentage,
    wc_agg.num_creation_pages,
    wa_agg.num_access_pages,
    (d.d_year * 4 + d.d_quarter_seq) AS year_quarter_key,
    CASE WHEN s_agg.s_state IN ('CA','NY','TX') THEN 'High' ELSE 'Low' END AS region_type
FROM date_dim d
LEFT JOIN promo_agg p_agg ON p_agg.date_sk = d.d_date_sk
LEFT JOIN store_agg s_agg ON s_agg.date_sk = d.d_date_sk
LEFT JOIN web_creation_agg wc_agg ON wc_agg.date_sk = d.d_date_sk
LEFT JOIN web_access_agg wa_agg ON wa_agg.date_sk = d.d_date_sk
WHERE p_agg.num_promotions IS NOT NULL
GROUP BY
    d.d_year,
    d.d_quarter_seq,
    s_agg.s_state,
    p_agg.i_category,
    p_agg.i_brand,
    p_agg.num_promotions,
    p_agg.total_promo_cost,
    p_agg.avg_item_price,
    p_agg.active_discount_cost,
    s_agg.num_stores,
    s_agg.total_tax_percentage,
    wc_agg.num_creation_pages,
    wa_agg.num_access_pages,
    (d.d_year * 4 + d.d_quarter_seq),
    CASE WHEN s_agg.s_state IN ('CA','NY','TX') THEN 'High' ELSE 'Low' END
HAVING p_agg.total_promo_cost > 1000
ORDER BY p_agg.total_promo_cost DESC
LIMIT 100
