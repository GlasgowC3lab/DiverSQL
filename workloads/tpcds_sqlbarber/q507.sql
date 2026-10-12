SELECT s.s_state,
       p.p_channel_email,
       SUM(ss.ss_net_paid) AS total_net_paid,
       COUNT(*) AS transaction_count
FROM store_sales ss
INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
INNER JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE ss.ss_sold_date_sk >= 2451524
  AND ss.ss_sold_date_sk <= 2452109
  AND s.s_state = 'TN'
GROUP BY s.s_state, p.p_channel_email
