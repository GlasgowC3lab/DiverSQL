WITH returns_2001 AS (
   SELECT
       i.i_item_id AS i_item_id,
       i.i_item_desc AS i_item_desc,
       d.d_year AS d_year,
       SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
       ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(sr.sr_return_amt_inc_tax) DESC) AS category_rank
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN promotion p ON p.p_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
     AND i.i_wholesale_cost > 10
     AND p.p_channel_catalog = 'N'
   GROUP BY i.i_item_id, i.i_item_desc, d.d_year, i.i_category
),
returns_2002 AS (
   SELECT
       i.i_item_id AS i_item_id,
       i.i_item_desc AS i_item_desc,
       d.d_year AS d_year,
       SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
       ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(sr.sr_return_amt_inc_tax) DESC) AS category_rank
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN promotion p ON p.p_item_sk = i.i_item_sk
   WHERE d.d_year = 2002
     AND i.i_wholesale_cost <= 10
     AND p.p_channel_radio = 'N'
   GROUP BY i.i_item_id, i.i_item_desc, d.d_year, i.i_category
)
SELECT i_item_id,
       i_item_desc,
       d_year,
       total_return_amt,
       category_rank
FROM returns_2001
UNION ALL
SELECT i_item_id,
       i_item_desc,
       d_year,
       total_return_amt,
       category_rank
FROM returns_2002
ORDER BY d_year,
         category_rank,
         i_item_id
LIMIT 100
