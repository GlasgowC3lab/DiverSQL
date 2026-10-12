WITH web_agg AS (
    SELECT
        d.d_date_sk,
        COUNT(DISTINCT wp.wp_web_page_id) AS cnt_pages_created,
        AVG(wp.wp_image_count) AS avg_image_count,
        SUM(wp.wp_max_ad_count) AS total_max_ad_count,
        MAX(wp.wp_char_count) AS max_char_count
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk
),
store_agg AS (
    SELECT
        d.d_date_sk,
        s.s_store_sk,
        s.s_store_id,
        s.s_city,
        s.s_state,
        COUNT(DISTINCT cr.cr_order_number) AS cnt_returns,
        SUM(cr.cr_net_loss) AS sum_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        SUM(cr.cr_fee) AS sum_fee,
        SUM(CASE WHEN cr.cr_return_quantity > 1 THEN 1 ELSE 0 END) AS cnt_multi_item
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk, s.s_store_sk, s.s_store_id, s.s_city, s.s_state
)
SELECT
    d.d_date,
    sagg.s_store_id,
    sagg.s_city,
    sagg.s_state,
    sagg.cnt_returns,
    sagg.sum_net_loss,
    sagg.avg_return_amount,
    sagg.sum_fee,
    sagg.cnt_multi_item,
    wagg.cnt_pages_created,
    wagg.avg_image_count,
    wagg.total_max_ad_count,
    wagg.max_char_count,
    RANK() OVER (PARTITION BY d.d_date ORDER BY sagg.sum_net_loss DESC) AS store_loss_rank
FROM date_dim d
JOIN store_agg sagg ON sagg.d_date_sk = d.d_date_sk
LEFT JOIN web_agg wagg ON wagg.d_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND sagg.s_state = 'CA'
ORDER BY d.d_date, store_loss_rank
LIMIT 200
