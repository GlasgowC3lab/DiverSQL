SELECT i.i_item_id,
       i.i_product_name,
       i.i_current_price,
       COUNT(p.p_promo_sk) AS promo_count,
       SUM(p.p_cost) AS total_promo_cost
FROM tpcds.item i
JOIN tpcds.promotion p
  ON p.p_item_sk = i.i_item_sk
WHERE i.i_current_price > 5.00
  AND p.p_channel_email = 'N'
GROUP BY i.i_item_id, i.i_product_name, i.i_current_price
ORDER BY total_promo_cost DESC
LIMIT 10
