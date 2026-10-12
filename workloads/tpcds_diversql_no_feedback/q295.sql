WITH store_agg AS (
  SELECT
    d.d_year AS year,
    'Store' AS dim_type,
    s.s_store_name AS dim_name,
    SUM(ss.ss_net_paid) AS total_net_paid
  FROM store_sales ss
  RIGHT JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  LEFT JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  GROUP BY CUBE(d.d_year, s.s_store_name)
),
promo_agg AS (
  SELECT
    d.d_year AS year,
    'Promotion' AS dim_type,
    p.p_promo_name AS dim_name,
    SUM(cs.cs_net_paid) AS total_net_paid
  FROM catalog_sales cs
  RIGHT JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  LEFT JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  GROUP BY CUBE(d.d_year, p.p_promo_name)
)
SELECT
  year,
  dim_type,
  dim_name,
  total_net_paid
FROM store_agg
UNION ALL
SELECT
  year,
  dim_type,
  dim_name,
  total_net_paid
FROM promo_agg
ORDER BY year DESC NULLS LAST, total_net_paid DESC
LIMIT 100
