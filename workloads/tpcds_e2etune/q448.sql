WITH promo_sales AS (
  SELECT
    s.s_market_desc,
    t.t_shift,
    p.p_promo_name,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_net_paid) AS total_net_paid,
    COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count
  FROM store_sales ss
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  WHERE p.p_channel_tv = 'Y'
    AND p.p_start_date_sk BETWEEN 2450118 AND 2450675
    AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450600
  GROUP BY s.s_market_desc, t.t_shift, p.p_promo_name
), ranked AS (
  SELECT
    s_market_desc,
    t_shift,
    p_promo_name,
    total_net_profit,
    total_net_paid,
    transaction_count,
    ROW_NUMBER() OVER (PARTITION BY s_market_desc, t_shift ORDER BY total_net_profit DESC) AS promo_rank
  FROM promo_sales
)
SELECT
  s_market_desc,
  t_shift,
  p_promo_name,
  total_net_profit,
  total_net_paid,
  transaction_count,
  promo_rank
FROM ranked
WHERE promo_rank <= 5
ORDER BY s_market_desc, t_shift, promo_rank
