WITH active_sites AS (
  SELECT web_site_sk, web_site_id, web_name, web_country, web_tax_percentage
  FROM web_site
  WHERE web_rec_start_date >= DATE '2020-01-01'
),
cust_site_agg AS (
  SELECT
    w.web_site_id,
    w.web_name,
    w.web_country,
    COUNT(DISTINCT c.c_customer_sk) AS cust_cnt,
    AVG(c.c_birth_year) AS avg_birth_year,
    AVG(w.web_tax_percentage) AS avg_tax_pct
  FROM
    customer c
  JOIN
    active_sites w
      ON c.c_birth_country = w.web_country
  WHERE
    c.c_birth_year >= 1970
  GROUP BY
    w.web_site_id,
    w.web_name,
    w.web_country
  HAVING
    COUNT(DISTINCT c.c_customer_sk) > 5
)
SELECT
  web_site_id,
  web_name,
  web_country,
  cust_cnt,
  avg_birth_year,
  avg_tax_pct,
  RANK() OVER (ORDER BY cust_cnt DESC) AS site_rank
FROM
  cust_site_agg
ORDER BY
  cust_cnt DESC
LIMIT 20
