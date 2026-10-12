WITH country_stats AS (
  SELECT c.c_birth_country,
         AVG(DATE_DIFF('day', ds.d_date, dr.d_date)) AS avg_days_between,
         COUNT(*) AS cust_cnt
  FROM customer c
  JOIN date_dim ds ON c.c_first_shipto_date_sk = ds.d_date_sk
  JOIN date_dim dr ON c.c_first_sales_date_sk = dr.d_date_sk
  WHERE c.c_birth_month = 5
    AND ds.d_holiday = 'Y'
  GROUP BY c.c_birth_country
  HAVING COUNT(*) >= 10
)
SELECT cs.c_birth_country,
       cs.avg_days_between,
       cs.cust_cnt,
       RANK() OVER (ORDER BY cs.avg_days_between DESC) AS rank
FROM country_stats cs
ORDER BY cs.avg_days_between DESC
LIMIT 5
