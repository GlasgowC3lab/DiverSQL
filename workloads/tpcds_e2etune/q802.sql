WITH store_profit AS (
  SELECT
    s.s_store_sk,
    s.s_store_name,
    s.s_state,
    s.s_city,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(*) AS sales_cnt
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE s.s_country = 'United States'
    AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
  GROUP BY s.s_store_sk, s.s_store_name, s.s_state, s.s_city
)
SELECT
  s_state,
  s_city,
  s_store_name,
  total_net_profit,
  avg_discount,
  sales_cnt,
  RANK() OVER (PARTITION BY s_state ORDER BY total_net_profit DESC) AS state_rank
FROM store_profit
WHERE total_net_profit > 0
ORDER BY total_net_profit DESC
LIMIT 100
