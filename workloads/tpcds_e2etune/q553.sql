SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_floor_space,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    ROUND(SUM(ss.ss_net_profit) / NULLIF(s.s_floor_space, 0), 2) AS profit_per_sqft,
    ROUND(SUM(ss.ss_net_profit) / NULLIF(SUM(ss.ss_net_paid), 0), 4) AS profit_margin,
    ROUND(AVG(ss.ss_ext_discount_amt / NULLIF(ss.ss_ext_list_price, 0)), 4) AS avg_discount_rate,
    SUM(ss.ss_ext_tax) AS total_tax,
    RANK() OVER (ORDER BY SUM(ss.ss_net_profit) / NULLIF(s.s_floor_space, 0) DESC) AS profit_per_sqft_rank
FROM store_sales ss
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
WHERE s.s_state = 'CA'
  AND s.s_tax_percentage > 5.00
  AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2451088
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_floor_space
HAVING SUM(ss.ss_net_profit) > 10000
ORDER BY profit_per_sqft DESC
LIMIT 20
