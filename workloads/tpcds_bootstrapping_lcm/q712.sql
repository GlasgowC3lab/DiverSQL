WITH wp_creation_agg AS (
    SELECT
        wp_creation_date_sk AS d_date_sk,
        AVG(wp_image_count) AS avg_image_cnt_creation,
        AVG(wp_char_count) AS avg_char_cnt_creation
    FROM web_page
    GROUP BY wp_creation_date_sk
),
wp_access_agg AS (
    SELECT
        wp_access_date_sk AS d_date_sk,
        AVG(wp_image_count) AS avg_image_cnt_access,
        AVG(wp_char_count) AS avg_char_cnt_access
    FROM web_page
    GROUP BY wp_access_date_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_sold.d_year,
    d_sold.d_month_seq,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(p.p_cost) AS avg_promo_cost,
    MAX(p.p_discount_active) AS promo_discount_active,
    MIN(d_promo_start.d_date) AS promo_start_date,
    MAX(d_promo_end.d_date) AS promo_end_date,
    AVG(wc.avg_image_cnt_creation) AS avg_image_cnt_created_on_sale_day,
    AVG(wa.avg_image_cnt_access) AS avg_image_cnt_accessed_on_sale_day,
    AVG(wc.avg_char_cnt_creation) AS avg_char_cnt_created_on_sale_day,
    AVG(wa.avg_char_cnt_access) AS avg_char_cnt_accessed_on_sale_day
FROM store_sales ss
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
LEFT JOIN wp_creation_agg wc
    ON wc.d_date_sk = d_sold.d_date_sk
LEFT JOIN wp_access_agg wa
    ON wa.d_date_sk = d_sold.d_date_sk
WHERE (s.s_closed_date_sk IS NULL OR d_closed.d_date > d_sold.d_date)
  AND d_sold.d_year = 2022
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_sold.d_year,
    d_sold.d_month_seq
ORDER BY total_net_profit DESC
LIMIT 100
