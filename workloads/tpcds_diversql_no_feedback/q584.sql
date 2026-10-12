WITH filtered AS (
  SELECT
    cr.cr_returned_date_sk,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cr.cr_reason_sk,
    cr.cr_catalog_page_sk,
    cp.cp_department,
    cp.cp_description,
    CASE WHEN regexp_like(cp.cp_description, 'women') THEN 1 ELSE 0 END AS has_women,
    regexp_extract(cp.cp_description, '^(\\w+)') AS first_word
  FROM catalog_returns cr
  JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE cp.cp_description LIKE '%women%'
    AND regexp_like(cp.cp_description, 'principles')
)
SELECT
  d.d_year,
  f.cp_department,
  r.r_reason_desc,
  SUM(f.cr_return_amount) AS total_return_amount,
  AVG(f.cr_return_quantity) AS avg_return_qty,
  SUM(f.has_women) AS count_women_mentions,
  ANY_VALUE(f.first_word) AS example_first_word
FROM filtered f
JOIN date_dim d
  ON f.cr_returned_date_sk = d.d_date_sk
JOIN reason r
  ON f.cr_reason_sk = r.r_reason_sk
GROUP BY CUBE (d.d_year, f.cp_department, r.r_reason_desc)
ORDER BY total_return_amount DESC
LIMIT 100
