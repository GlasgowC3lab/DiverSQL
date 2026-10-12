WITH returns_aggregated AS (
    SELECT
        s.s_store_id,
        s.s_city,
        p.p_promo_name,
        p.p_channel_email,
        d.d_year,
        d.d_moy AS month_num,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2022
      AND p.p_channel_email = 'Y'
    GROUP BY
        s.s_store_id,
        s.s_city,
        p.p_promo_name,
        p.p_channel_email,
        d.d_year,
        d.d_moy
)
SELECT
    s_store_id,
    s_city,
    p_promo_name,
    p_channel_email,
    d_year,
    month_num,
    total_net_loss,
    return_count,
    avg_return_amount,
    distinct_web_pages,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_net_loss DESC) AS rank_in_store
FROM returns_aggregated
ORDER BY total_net_loss DESC
LIMIT 100
