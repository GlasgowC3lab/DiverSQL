WITH intersect_orders AS (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, 'damaged')
    INTERSECT
    SELECT wr.wr_order_number
    FROM web_returns wr
    JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    WHERE r2.r_reason_desc LIKE '%missing%'
)
SELECT
    i.i_brand,
    i.i_item_id,
    CONCAT(i.i_brand, ' ', i.i_item_id) AS brand_item,
    REGEXP_EXTRACT(i.i_item_desc, '(\\w+)', 1) AS first_word_desc,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_profit) AS total_net_profit,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Positive' ELSE 'Non-Positive' END AS profit_flag,
    (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS avg_net_profit_all
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cs.cs_order_number IN (SELECT cr_order_number FROM intersect_orders)
  AND i.i_brand LIKE 'A%'
  AND regexp_like(i.i_item_desc, '^[A-Z]{3}')
GROUP BY
    i.i_brand,
    i.i_item_id,
    CONCAT(i.i_brand, ' ', i.i_item_id),
    REGEXP_EXTRACT(i.i_item_desc, '(\\w+)', 1)
ORDER BY total_net_profit DESC
LIMIT 100
