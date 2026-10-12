SELECT d.d_year,
       wp.wp_type,
       SUM(cr.cr_return_amount) AS total_return_amount,
       AVG(cr.cr_return_quantity) AS avg_return_quantity
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN web_page wp
  ON wp.wp_creation_date_sk = d.d_date_sk
WHERE d.d_year = 1911
  AND wp.wp_type = 'protected                                         '
GROUP BY d.d_year, wp.wp_type
ORDER BY d.d_year, wp.wp_type
