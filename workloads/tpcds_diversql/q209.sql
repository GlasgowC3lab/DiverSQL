WITH sampled_items AS (
    SELECT i_item_sk,
           i_category,
           i_category_id
    FROM item TABLESAMPLE BERNOULLI (10)
),
store_ret AS (
    SELECT d.d_year AS year,
           si.i_category AS category,
           SUM(sr.sr_return_amt) AS total_return_amount,
           SUM(sr.sr_return_quantity) AS total_return_quantity,
           'store' AS source
    FROM store_returns sr
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN sampled_items si
      ON sr.sr_item_sk = si.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, si.i_category
),
catalog_ret AS (
    SELECT d.d_year AS year,
           ci.i_category AS category,
           SUM(cr.cr_return_amount) AS total_return_amount,
           SUM(cr.cr_return_quantity) AS total_return_quantity,
           'catalog' AS source
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN sampled_items ci
      ON cr.cr_item_sk = ci.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, ci.i_category
)
SELECT year,
       category,
       total_return_amount,
       total_return_quantity,
       source
FROM (
    SELECT * FROM store_ret
    UNION ALL
    SELECT * FROM catalog_ret
) combined
ORDER BY year DESC, total_return_amount DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
