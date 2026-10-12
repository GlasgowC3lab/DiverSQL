WITH filtered_sales AS (
    SELECT
        i.i_category,
        regexp_extract(p.p_promo_name, '(\\d+)%', 1) AS discount_percent,
        cs.cs_net_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE regexp_like(p.p_promo_name, 'Discount')
      AND i.i_product_name LIKE '%Gold%'
)
SELECT
    i_category,
    discount_percent,
    concat(i_category, '_', discount_percent) AS category_discount_key,
    sum(cs_net_profit) AS total_net_profit
FROM filtered_sales
GROUP BY ROLLUP (i_category, discount_percent)
ORDER BY i_category ASC NULLS LAST,
         discount_percent ASC NULLS LAST
LIMIT 100
