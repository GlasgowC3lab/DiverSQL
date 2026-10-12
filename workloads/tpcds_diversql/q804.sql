WITH base AS (
   SELECT
       wr.wr_order_number,
       wr.wr_return_amt,
       wr.wr_return_quantity,
       wr.wr_reversed_charge,
       wr.wr_returned_date_sk,
       wp.wp_type,
       wp.wp_rec_start_date,
       r.r_reason_desc,
       r.r_reason_id,
       wp.wp_creation_date_sk
   FROM web_returns wr
   JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   WHERE wp.wp_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
     AND wp.wp_type IN ('homepage', 'product')
     AND r.r_reason_desc LIKE '%damage%'
     AND wr.wr_reversed_charge > 200
     AND wr.wr_return_quantity >= 1
     AND wp.wp_creation_date_sk = 2450805
     AND wr.wr_returned_date_sk IN (2450400, 2450401)
),
exclude_set AS (
   SELECT DISTINCT wr_order_number
   FROM web_returns
   WHERE wr_return_amt < 50
),
filtered AS (
   SELECT *
   FROM base
   WHERE wr_order_number NOT IN (SELECT wr_order_number FROM exclude_set)
     AND EXISTS (
         SELECT 1
         FROM web_page wp2
         WHERE wp2.wp_web_page_sk = 99999
           AND wp2.wp_type = 'homepage'
     )
),
agg_all AS (
   SELECT
       wp_type,
       r_reason_desc,
       COUNT(DISTINCT wr_order_number) AS order_cnt,
       SUM(wr_return_amt) AS total_return_amt,
       AVG(wr_reversed_charge) AS avg_reversed_charge,
       MIN(wr_return_quantity) AS min_qty,
       MAX(wr_return_quantity) AS max_qty
   FROM filtered
   GROUP BY CUBE (wp_type, r_reason_desc)
),
agg_product AS (
   SELECT
       wp_type,
       r_reason_desc,
       COUNT(DISTINCT wr_order_number) AS order_cnt,
       SUM(wr_return_amt) AS total_return_amt,
       AVG(wr_reversed_charge) AS avg_reversed_charge,
       MIN(wr_return_quantity) AS min_qty,
       MAX(wr_return_quantity) AS max_qty
   FROM filtered
   WHERE wp_type = 'product'
   GROUP BY CUBE (wp_type, r_reason_desc)
)
SELECT *
FROM (
    SELECT * FROM agg_all
    EXCEPT
    SELECT * FROM agg_product
) diff
ORDER BY total_return_amt DESC, wp_type
OFFSET 10 LIMIT 100
