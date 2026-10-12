WITH daily_web_page AS (
    SELECT
        wp_creation_date_sk AS date_sk,
        COUNT(*) AS wp_created_cnt
    FROM web_page
    GROUP BY wp_creation_date_sk
),
promo_inventory AS (
    SELECT
        d.d_year,
        d.d_moy AS month,
        p.p_channel_demo,
        COUNT(DISTINCT p.p_promo_sk) AS promo_cnt,
        SUM(i.inv_quantity_on_hand) AS total_inventory,
        AVG(p.p_cost) AS avg_promo_cost,
        SUM(COALESCE(dw.wp_created_cnt, 0)) AS total_web_pages_created
    FROM date_dim d
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN promotion p
        ON d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
        AND i.inv_item_sk = p.p_item_sk
    LEFT JOIN daily_web_page dw ON dw.date_sk = d.d_date_sk
    WHERE d.d_weekend = 'N'
      AND p.p_discount_active = 'Y'
    GROUP BY d.d_year, d.d_moy, p.p_channel_demo
    HAVING SUM(i.inv_quantity_on_hand) > 1000
)
SELECT
    pi.d_year,
    pi.month,
    pi.p_channel_demo,
    pi.promo_cnt,
    pi.total_inventory,
    pi.avg_promo_cost,
    pi.total_web_pages_created,
    pi.total_inventory * pi.avg_promo_cost AS inventory_cost_product,
    RANK() OVER (PARTITION BY pi.d_year, pi.month ORDER BY pi.total_inventory DESC) AS channel_rank
FROM promo_inventory pi
ORDER BY pi.d_year, pi.month, channel_rank
LIMIT 100
