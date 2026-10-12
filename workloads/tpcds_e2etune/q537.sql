WITH bill_stats AS (
  SELECT
    ws.ws_order_number,
    ws.ws_net_profit,
    ws.ws_ext_discount_amt,
    ws.ws_sold_date_sk,
    b.c_birth_year,
    CASE
      WHEN b.c_birth_year < 1940 THEN 'Pre-1940'
      WHEN b.c_birth_year BETWEEN 1940 AND 1960 THEN '1940-1960'
      ELSE 'Post-1960'
    END AS bill_age_group,
    b.c_salutation
  FROM web_sales ws
  JOIN customer b ON ws.ws_bill_customer_sk = b.c_customer_sk
  WHERE b.c_salutation IN ('Mr.', 'Mrs.', 'Dr.')
),
ship_stats AS (
  SELECT
    ws.ws_order_number,
    s.c_birth_year,
    CASE
      WHEN s.c_birth_year < 1940 THEN 'Pre-1940'
      WHEN s.c_birth_year BETWEEN 1940 AND 1960 THEN '1940-1960'
      ELSE 'Post-1960'
    END AS ship_age_group,
    s.c_salutation
  FROM web_sales ws
  JOIN customer s ON ws.ws_ship_customer_sk = s.c_customer_sk
  WHERE s.c_salutation IN ('Mr.', 'Mrs.', 'Dr.')
)
SELECT
  b.bill_age_group,
  s.ship_age_group,
  COUNT(DISTINCT b.ws_order_number) AS order_cnt,
  SUM(b.ws_net_profit) AS total_profit,
  AVG(b.ws_ext_discount_amt) AS avg_discount,
  RANK() OVER (ORDER BY SUM(b.ws_net_profit) DESC) AS profit_rank
FROM bill_stats b
JOIN ship_stats s ON b.ws_order_number = s.ws_order_number
WHERE b.ws_sold_date_sk BETWEEN 2452000 AND 2452500
GROUP BY b.bill_age_group, s.ship_age_group
HAVING SUM(b.ws_net_profit) > 5000
ORDER BY profit_rank
LIMIT 5
