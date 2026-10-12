SELECT
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_state,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(p.p_cost) FILTER (WHERE p.p_discount_active = 'Y') AS avg_active_promo_cost,
    SUM(CASE WHEN wp.wp_type = 'Landing' THEN wp.wp_image_count ELSE 0 END) AS total_landing_images,
    SUM(CASE WHEN wp.wp_type = 'Product' THEN wp.wp_link_count ELSE 0 END) AS total_product_links,
    COUNT(DISTINCT p.p_promo_id) AS promo_count,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(s.s_tax_percentage) AS avg_tax_pct,
    MIN(d_access.d_day_name) AS first_access_day,
    MAX(d_closed.d_current_quarter) AS last_closed_quarter
FROM
    store_returns sr
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ret.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE
    d_ret.d_year = 2022
    AND s.s_state = 'CA'
    AND p.p_discount_active = 'Y'
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_state
HAVING
    SUM(sr.sr_net_loss) > 1000
ORDER BY
    total_net_loss DESC
LIMIT 100
