SELECT d.d_year,
       s.s_store_name,
       i.i_item_id,
       i.i_item_desc,
       SUM(ss.ss_net_paid) AS total_net_paid,
       SUM(ss.ss_net_profit) AS total_net_profit,
       COUNT(*) AS num_transactions
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE d.d_year BETWEEN 1998 AND 2002
  AND s.s_state = 'CA'
  AND i.i_brand = 'Brand#12'
  AND p.p_discount_active = 'Y'
GROUP BY d.d_year, s.s_store_name, i.i_item_id, i.i_item_desc
ORDER BY total_net_paid DESC
LIMIT 20
