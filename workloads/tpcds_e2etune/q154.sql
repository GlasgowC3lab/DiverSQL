WITH sales_by_date AS (
  SELECT ws_sold_date_sk,
         SUM(ws_net_profit) AS total_profit,
         SUM(ws_ext_sales_price) AS total_sales,
         COUNT(*) AS sales_cnt
  FROM web_sales
  WHERE ws_sold_date_sk BETWEEN 2451000 AND 2452000
  GROUP BY ws_sold_date_sk
),
city_income_agg AS (
  SELECT s.s_city,
         ib.ib_income_band_sk,
         SUM(sb.total_profit) AS city_income_profit,
         AVG(sb.total_sales) AS avg_daily_sales
  FROM store s
  CROSS JOIN income_band ib
  JOIN sales_by_date sb
    ON sb.ws_sold_date_sk BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
   AND (s.s_closed_date_sk IS NULL OR sb.ws_sold_date_sk <= s.s_closed_date_sk)
  WHERE s.s_state = 'CA'
  GROUP BY s.s_city, ib.ib_income_band_sk
  HAVING SUM(sb.total_profit) > 0
)
SELECT ci.s_city,
       ci.ib_income_band_sk,
       ci.city_income_profit,
       ci.avg_daily_sales,
       RANK() OVER (ORDER BY ci.city_income_profit DESC) AS profit_rank
FROM city_income_agg ci
ORDER BY ci.city_income_profit DESC
LIMIT 100
