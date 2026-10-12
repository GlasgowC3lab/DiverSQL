WITH promo_stats AS (
    SELECT i.i_brand,
           i.i_category,
           COUNT(DISTINCT i.i_item_id) AS distinct_items,
           SUM(p.p_cost) AS total_promo_cost,
           AVG(i.i_current_price) AS avg_current_price,
           SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) AS active_discount_cost
    FROM item i
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE i.i_wholesale_cost >= 5.00
      AND i.i_rec_end_date >= DATE '2020-01-01'
      AND p.p_start_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY i.i_brand, i.i_category
    HAVING SUM(p.p_cost) > 1000
)
SELECT *,
       RANK() OVER (ORDER BY total_promo_cost DESC) AS brand_category_rank
FROM promo_stats
ORDER BY total_promo_cost DESC
LIMIT 50
