WITH cc_sample AS (
   SELECT
       cc.cc_call_center_sk,
       cc.cc_name,
       cc.cc_open_date_sk,
       d.d_date,
       d.d_year
   FROM call_center cc
   TABLESAMPLE BERNOULLI (10)
   JOIN date_dim d
     ON cc.cc_open_date_sk = d.d_date_sk
),
cp_sample AS (
   SELECT
       cp.cp_catalog_page_sk,
       cp.cp_description,
       cp.cp_start_date_sk,
       d.d_date,
       d.d_year
   FROM catalog_page cp
   JOIN date_dim d
     ON cp.cp_start_date_sk = d.d_date_sk
)
SELECT
   COALESCE(cc.cc_name, cp.cp_description) AS title,
   COALESCE(cc.d_year, cp.d_year)                AS year,
   CASE
       WHEN cc.cc_name IS NOT NULL THEN 'CALL_CENTER'
       WHEN cp.cp_description IS NOT NULL THEN 'CATALOG_PAGE'
       ELSE 'UNKNOWN'
   END                                           AS source,
   -- string processing
   CASE WHEN cc.cc_name IS NOT NULL AND regexp_like(cc.cc_name, '^.*Center$') THEN 1 ELSE 0 END          AS name_ends_with_center,
   CASE WHEN cp.cp_description IS NOT NULL AND cp.cp_description LIKE '%catalog%' THEN 1 ELSE 0 END   AS desc_contains_catalog,
   concat(
       COALESCE(cc.cc_name, ''),
       CASE WHEN cc.cc_name IS NOT NULL AND cp.cp_description IS NOT NULL THEN ' | ' ELSE '' END,
       COALESCE(cp.cp_description, '')
   )                                            AS combined_text,
   -- correlated scalar subqueries
   (SELECT sum(ss.ss_net_paid)
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk = cc.cc_open_date_sk)                      AS total_sales_on_open_date,
   (SELECT count(*)
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk = cp.cp_start_date_sk)                  AS web_returns_on_start_date
FROM cc_sample cc
FULL OUTER JOIN cp_sample cp
   ON cc.d_date = cp.d_date
WHERE
   (cc.cc_name IS NOT NULL AND regexp_like(cc.cc_name, '^.*Center.*$'))
   OR (cp.cp_description IS NOT NULL AND cp.cp_description LIKE '%catalog%')
LIMIT 100
