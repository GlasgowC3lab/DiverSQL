WITH base AS (
  SELECT
    c.c_birth_year,
    c.c_birth_month,
    COUNT(*) AS num_customers,
    AVG(sales.d_year - c.c_birth_year) AS avg_age_at_first_sales
  FROM customer c
  JOIN date_dim ship ON c.c_first_shipto_date_sk = ship.d_date_sk
  JOIN date_dim sales ON c.c_first_sales_date_sk = sales.d_date_sk
  WHERE c.c_birth_year BETWEEN 1950 AND 1970
    AND ship.d_month_seq BETWEEN 1 AND 6
    AND ship.d_year = 2020
  GROUP BY c.c_birth_year, c.c_birth_month
  HAVING COUNT(*) > 10
)
SELECT
  b.c_birth_year,
  b.c_birth_month,
  b.num_customers,
  b.avg_age_at_first_sales,
  RANK() OVER (ORDER BY b.avg_age_at_first_sales DESC) AS age_rank
FROM base b
ORDER BY b.avg_age_at_first_sales DESC
