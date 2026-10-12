WITH sales_agg AS (
  SELECT
    s.s_store_name AS store_name,
    s.s_state AS store_state,
    ca.ca_county AS county,
    t.t_hour AS hour_of_day,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount_amt,
    COUNT(*) AS transaction_cnt
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  WHERE s.s_country = 'United States'
    AND s.s_state = 'CA'
    AND ca.ca_zip = '86192'
    AND cd.cd_credit_rating IN ('Excellent', 'Good')
    AND t.t_hour BETWEEN 12 AND 14
  GROUP BY s.s_store_name, s.s_state, ca.ca_county, t.t_hour
),
ranked_sales AS (
  SELECT
    store_name,
    store_state,
    county,
    hour_of_day,
    total_net_profit,
    avg_discount_amt,
    transaction_cnt,
    ROW_NUMBER() OVER (PARTITION BY hour_of_day ORDER BY total_net_profit DESC) AS rank_in_hour
  FROM sales_agg
)
SELECT
  store_name,
  store_state,
  county,
  hour_of_day,
  total_net_profit,
  avg_discount_amt,
  transaction_cnt,
  rank_in_hour
FROM ranked_sales
WHERE rank_in_hour <= 3
ORDER BY hour_of_day, rank_in_hour
