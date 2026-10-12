SELECT d.d_year, SUM(cr.cr_return_amount) AS total_return_amount FROM catalog_returns cr JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk WHERE d.d_year = 1936 GROUP BY d.d_year
