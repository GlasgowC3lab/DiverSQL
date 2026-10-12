SELECT
    i.i_brand,
    i.i_category,
    COUNT(DISTINCT p.p_promo_sk) AS promo_cnt,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(i.i_current_price) AS avg_item_price,
    RANK() OVER (ORDER BY SUM(p.p_cost) DESC) AS cost_rank
FROM
    promotion p
JOIN
    item i
    ON p.p_item_sk = i.i_item_sk
WHERE
    p.p_cost > 5000
    AND p.p_discount_active = 'Y'
    AND i.i_current_price BETWEEN 10 AND 1000
GROUP BY
    i.i_brand,
    i.i_category
HAVING
    SUM(p.p_cost) > 100000
ORDER BY
    total_promo_cost DESC
LIMIT 50
