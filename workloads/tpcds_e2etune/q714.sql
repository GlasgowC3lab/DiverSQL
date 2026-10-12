WITH agg AS (
  SELECT
    c.c_birth_country AS birth_country,
    ca.ca_state AS state,
    sum(ss.ss_net_profit) AS total_profit,
    sum(ss.ss_net_paid) AS total_paid,
    avg(ss.ss_ext_discount_amt) AS avg_discount,
    count(distinct c.c_customer_sk) AS cust_cnt
  FROM store_sales ss
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
  WHERE c.c_birth_country IN ('CHILE','MEXICO')
    AND c.c_birth_month BETWEEN 1 AND 6
    AND c.c_birth_day > 10
    AND ss.ss_net_paid > 0
    AND hd.hd_vehicle_count >= 2
  GROUP BY c.c_birth_country, ca.ca_state
)
SELECT
  birth_country,
  state,
  total_profit,
  total_paid,
  avg_discount,
  cust_cnt,
  rank() OVER (PARTITION BY birth_country ORDER BY total_profit DESC) AS profit_state_rank,
  total_profit / sum(total_profit) OVER (PARTITION BY birth_country) AS profit_pct_of_country
FROM agg
ORDER BY birth_country, profit_state_rank
LIMIT 100
