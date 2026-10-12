WITH agg AS (
    SELECT
        i.i_category,
        i.i_brand,
        SUM(p.p_cost) AS total_promo_cost,
        AVG(i.i_current_price) AS avg_item_price,
        COUNT(DISTINCT p.p_promo_id) AS promo_cnt
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    WHERE p.p_discount_active = 'Y'
      AND p.p_channel_email = 'Y'
      AND p.p_start_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY i.i_category, i.i_brand
    HAVING SUM(p.p_cost) > 10000
)
SELECT
    a.i_category,
    a.i_brand,
    a.total_promo_cost,
    a.avg_item_price,
    a.promo_cnt,
    ROW_NUMBER() OVER (PARTITION BY a.i_category ORDER BY a.total_promo_cost DESC) AS brand_rank_in_category,
    (SELECT AVG(cc.cc_employees) FROM call_center cc WHERE cc.cc_country = 'United States') AS avg_us_employees
FROM agg a
ORDER BY a.total_promo_cost DESC
LIMIT 50
