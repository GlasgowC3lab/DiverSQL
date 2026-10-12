SELECT
  s.s_store_name,
  p.p_promo_name,
  td.t_sub_shift,
  i.i_category,
  SUM(ss.ss_net_profit) AS total_profit,
  AVG(ss.ss_quantity) AS avg_qty,
  SUM(inv.inv_quantity_on_hand) AS total_on_hand
FROM store_sales ss
JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
JOIN item i2 ON p.p_item_sk = i2.i_item_sk
JOIN inventory inv2 ON inv2.inv_item_sk = i2.i_item_sk
WHERE ca.ca_state = 'CA'
  AND ss.ss_net_profit > (SELECT avg(ss2.ss_net_profit) FROM store_sales ss2)
  AND p.p_channel_email = 'Y'
GROUP BY s.s_store_name, p.p_promo_name, td.t_sub_shift, i.i_category

UNION DISTINCT

SELECT
  s.s_store_name,
  p.p_promo_name,
  td.t_sub_shift,
  i.i_category,
  SUM(ss.ss_net_profit) AS total_profit,
  AVG(ss.ss_quantity) AS avg_qty,
  SUM(inv.inv_quantity_on_hand) AS total_on_hand
FROM store_sales ss
JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
JOIN item i2 ON p.p_item_sk = i2.i_item_sk
JOIN inventory inv2 ON inv2.inv_item_sk = i2.i_item_sk
WHERE ca.ca_state = 'CA'
  AND ss.ss_net_profit > (SELECT avg(ss2.ss_net_profit) FROM store_sales ss2)
  AND p.p_channel_dmail = 'Y'
GROUP BY s.s_store_name, p.p_promo_name, td.t_sub_shift, i.i_category

ORDER BY total_profit DESC
LIMIT 100
