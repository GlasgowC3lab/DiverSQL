WITH store_sales_agg AS (
  SELECT
    'Store' AS source_type,
    s.s_store_id AS identifier,
    SUM(ss.ss_net_paid) AS total_net_paid,
    (SELECT MAX(ss2.ss_net_paid) FROM store_sales ss2) AS max_store_net_paid
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE d.d_year = 2000
    AND EXISTS (
      SELECT 1 FROM store_sales ss3
      WHERE ss3.ss_store_sk = s.s_store_sk
        AND ss3.ss_net_paid > 1000
    )
  GROUP BY s.s_store_id
),
catalog_sales_agg AS (
  SELECT
    'Catalog' AS source_type,
    cp.cp_department AS identifier,
    SUM(cs.cs_net_paid) AS total_net_paid,
    (SELECT MAX(cs2.cs_net_paid) FROM catalog_sales cs2) AS max_store_net_paid
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE d.d_year = 2000
    AND cp.cp_department IS NOT NULL
  GROUP BY cp.cp_department
)
SELECT source_type, identifier, total_net_paid, max_store_net_paid
FROM (
  SELECT * FROM store_sales_agg
  UNION ALL
  SELECT * FROM catalog_sales_agg
) AS combined
ORDER BY total_net_paid DESC
LIMIT 100
