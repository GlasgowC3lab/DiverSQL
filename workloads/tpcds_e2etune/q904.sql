WITH store_agg AS (
  SELECT
    c.c_birth_country AS birth_country,
    td.t_shift AS shift,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ss.ss_ext_sales_price) AS store_sales,
    AVG(ss.ss_ext_discount_amt) AS store_avg_discount
  FROM store_sales ss
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  WHERE td.t_hour BETWEEN 9 AND 17
    AND c.c_preferred_cust_flag = 'Y'
  GROUP BY c.c_birth_country, td.t_shift
),
web_agg AS (
  SELECT
    c.c_birth_country AS birth_country,
    td.t_shift AS shift,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(ws.ws_ext_sales_price) AS web_sales,
    AVG(ws.ws_ext_discount_amt) AS web_avg_discount
  FROM web_sales ws
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  WHERE td.t_hour BETWEEN 9 AND 17
    AND c.c_preferred_cust_flag = 'Y'
  GROUP BY c.c_birth_country, td.t_shift
)
SELECT
  COALESCE(s.birth_country, w.birth_country) AS birth_country,
  COALESCE(s.shift, w.shift) AS shift,
  COALESCE(s.store_net_profit, 0) AS store_net_profit,
  COALESCE(w.web_net_profit, 0) AS web_net_profit,
  COALESCE(s.store_sales, 0) AS store_sales,
  COALESCE(w.web_sales, 0) AS web_sales,
  COALESCE(s.store_avg_discount, 0) AS store_avg_discount,
  COALESCE(w.web_avg_discount, 0) AS web_avg_discount,
  (COALESCE(s.store_net_profit, 0) + COALESCE(w.web_net_profit, 0)) AS total_net_profit,
  (COALESCE(s.store_sales, 0) + COALESCE(w.web_sales, 0)) AS total_sales
FROM store_agg s
FULL OUTER JOIN web_agg w
  ON s.birth_country = w.birth_country AND s.shift = w.shift
ORDER BY total_net_profit DESC
LIMIT 100
