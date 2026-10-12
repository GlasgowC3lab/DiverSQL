WITH filtered_catalog AS (
   SELECT
      cp_catalog_page_sk,
      cp_department,
      regexp_extract(cp_description, '([A-Za-z]+)', 1) AS first_word,
      CASE WHEN regexp_like(cp_description, '[0-9]{4}') THEN true ELSE false END AS has_year
   FROM catalog_page
   WHERE cp_description LIKE '%the%'
)
SELECT
   year,
   location,
   source,
   total_sales
FROM (
   SELECT
      d.d_year AS year,
      s.s_store_name AS location,
      'Store' AS source,
      SUM(ss.ss_net_paid) AS total_sales
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   WHERE s.s_city LIKE 'A%'
   GROUP BY d.d_year, s.s_store_name

   UNION

   SELECT
      d.d_year AS year,
      fc.first_word || '_' || fc.cp_department AS location,
      'Catalog' AS source,
      SUM(cs.cs_net_paid) AS total_sales
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN filtered_catalog fc ON cs.cs_catalog_page_sk = fc.cp_catalog_page_sk
   WHERE fc.has_year = true
   GROUP BY d.d_year, fc.first_word, fc.cp_department
) AS combined
ORDER BY total_sales DESC
LIMIT 100
