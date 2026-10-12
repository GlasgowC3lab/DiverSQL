WITH promo_summary AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        d_start.d_current_month AS promo_start_month,
        d_start.d_year AS promo_start_year,
        d_end.d_current_month AS promo_end_month,
        d_end.d_year AS promo_end_year,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_market_desc,
        SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand,
        COUNT(DISTINCT wp.wp_web_page_id) AS pages_created,
        COUNT(DISTINCT CASE WHEN wp.wp_access_date_sk IS NOT NULL THEN wp.wp_web_page_id END) AS pages_accessed,
        COUNT(DISTINCT CASE WHEN d_access.d_weekend = 'Y' THEN wp.wp_web_page_id END) AS weekend_pages_accessed,
        p.p_discount_active,
        p.p_channel_tv,
        p.p_channel_radio
    FROM promotion p
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    JOIN inventory i
        ON i.inv_date_sk = d_start.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_start.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_start.d_date_sk
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY
        p.p_promo_id,
        p.p_promo_name,
        d_start.d_current_month,
        d_start.d_year,
        d_end.d_current_month,
        d_end.d_year,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_market_desc,
        p.p_discount_active,
        p.p_channel_tv,
        p.p_channel_radio
)
SELECT
    ps.p_promo_id,
    ps.p_promo_name,
    ps.promo_start_month,
    ps.promo_start_year,
    ps.promo_end_month,
    ps.promo_end_year,
    ps.s_store_name,
    ps.s_city,
    ps.s_state,
    ps.s_market_desc,
    ps.total_quantity_on_hand,
    ps.pages_created,
    ps.pages_accessed,
    ps.weekend_pages_accessed,
    ps.p_discount_active,
    ps.p_channel_tv,
    ps.p_channel_radio,
    ROW_NUMBER() OVER (ORDER BY ps.total_quantity_on_hand DESC) AS promo_rank
FROM promo_summary ps
ORDER BY ps.total_quantity_on_hand DESC
LIMIT 100
