SELECT d.d_year,
       s.s_state,
       i.i_category,
       p.p_channel_dmail,
       SUM(ss.ss_net_profit) AS total_profit,
       COUNT(DISTINCT ss.ss_ticket_number) AS total_orders,
       AVG(ss.ss_quantity) AS avg_quantity,
       AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
WHERE d.d_year = 1998
  AND s.s_state IN ('CA','TX','NY')
GROUP BY d.d_year, s.s_state, i.i_category, p.p_channel_dmail
ORDER BY total_profit DESC
LIMIT 20
