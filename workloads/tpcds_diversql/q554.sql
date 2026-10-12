WITH recent_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        ca.ca_city,
        dd.d_year AS sales_year,
        dd.d_quarter_seq AS quarter_seq
    FROM customer c TABLESAMPLE BERNOULLI (10)
    JOIN customer_address ca
      ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN date_dim dd
      ON c.c_first_sales_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2020
      AND EXISTS (
          SELECT 1
          FROM household_demographics hd
          JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
          WHERE hd.hd_demo_sk = c.c_current_hdemo_sk
            AND ib.ib_upper_bound >= 80000
      )
),
web_access AS (
    SELECT
        wp.wp_customer_sk AS c_customer_sk,
        dd.d_year AS sales_year,
        dd.d_quarter_seq AS quarter_seq
    FROM web_page wp
    JOIN date_dim dd
      ON wp.wp_access_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2020
)
SELECT
    rc.c_customer_sk,
    rc.c_customer_id,
    rc.ca_city,
    rc.sales_year,
    rc.quarter_seq,
    (
        SELECT COUNT(DISTINCT s.s_store_sk)
        FROM store s
        JOIN date_dim sd
          ON s.s_closed_date_sk = sd.d_date_sk
        WHERE sd.d_year BETWEEN rc.sales_year AND rc.sales_year + 2
    ) AS recent_store_count
FROM recent_customers rc
INTERSECT
SELECT
    wa.c_customer_sk,
    c.c_customer_id,
    ca.ca_city,
    wa.sales_year,
    wa.quarter_seq,
    (
        SELECT COUNT(DISTINCT s.s_store_sk)
        FROM store s
        JOIN date_dim sd
          ON s.s_closed_date_sk = sd.d_date_sk
        WHERE sd.d_year BETWEEN wa.sales_year AND wa.sales_year + 2
    ) AS recent_store_count
FROM web_access wa
JOIN customer c
  ON wa.c_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON c.c_current_addr_sk = ca.ca_address_sk
JOIN date_dim d2
  ON c.c_first_sales_date_sk = d2.d_date_sk
WHERE d2.d_year = wa.sales_year
  AND EXISTS (
      SELECT 1
      FROM household_demographics hd
      JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
      WHERE hd.hd_demo_sk = c.c_current_hdemo_sk
        AND ib.ib_upper_bound >= 80000
  )
ORDER BY sales_year DESC, quarter_seq DESC, recent_store_count DESC
LIMIT 100
