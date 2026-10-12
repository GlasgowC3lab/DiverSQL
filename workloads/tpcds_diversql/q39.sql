SELECT
  item.i_item_id,
  item.i_product_name,
  item.i_color,
  promotion.p_promo_name,
  SUM(promotion.p_cost) AS total_promo_cost
FROM
  tpcds.item AS item
JOIN
  tpcds.promotion AS promotion
  ON promotion.p_item_sk = item.i_item_sk
WHERE
  item.i_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
  AND item.i_color = 'rosy'
  AND promotion.p_channel_radio = 'N'
GROUP BY
  item.i_item_id,
  item.i_product_name,
  item.i_color,
  promotion.p_promo_name
ORDER BY
  total_promo_cost DESC
