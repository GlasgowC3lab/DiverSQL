SELECT d_year AS year, COUNT(*) AS customer_count FROM customer JOIN date_dim ON customer.c_first_shipto_date_sk = date_dim.d_date_sk WHERE d_year = 1930 GROUP BY d_year
