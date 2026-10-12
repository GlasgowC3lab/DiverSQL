SELECT
    i.i_category AS category,
    p.p_promo_name AS promo_name,
    SUM(cs.cs_net_paid) AS total_sales,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN (
    SELECT inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
    FROM inventory
    WHERE inv_date_sk = 2451088
) inv ON inv.inv_item_sk = i.i_item_sk
WHERE cs.cs_sold_date_sk = 2450836
  AND i.i_brand_id = 9014012
GROUP BY i.i_category, p.p_promo_name
HAVING SUM(cs.cs_net_paid) > 32.76
