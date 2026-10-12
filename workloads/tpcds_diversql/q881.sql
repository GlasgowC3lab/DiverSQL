WITH sampled_sales AS (
    SELECT *
    FROM tpcds.store_sales
    TABLESAMPLE BERNOULLI (10)
),
max_year AS (
    SELECT max(d_year) AS max_yr FROM tpcds.date_dim
)
SELECT
    d.d_year,
    s.s_store_name,
    SUM(ss.ss_net_paid) AS total_net_paid,
    REGEXP_EXTRACT(s.s_store_name, '(A.*)') AS store_name_a_prefix
FROM sampled_sales ss
FULL OUTER JOIN tpcds.date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN tpcds.store s
    ON ss.ss_store_sk = s.s_store_sk
WHERE d.d_year = (SELECT max_yr FROM max_year)
  AND regexp_like(s.s_store_name, '^A.*')
  AND s.s_store_name LIKE '%Market%'
GROUP BY
    d.d_year,
    s.s_store_name,
    REGEXP_EXTRACT(s.s_store_name, '(A.*)')
ORDER BY total_net_paid DESC
OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY
