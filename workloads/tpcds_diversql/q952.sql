WITH base AS (
   SELECT
       cs.cs_sold_date_sk,
       cs.cs_sold_time_sk,
       cs.cs_item_sk,
       cs.cs_ext_sales_price,
       cs.cs_quantity,
       i.i_category,
       i.i_manager_id,
       i.i_wholesale_cost,
       cs_time.t_hour AS sold_hour,
       cs_time.t_sub_shift AS sold_shift,
       sr.sr_returned_date_sk,
       sr.sr_return_time_sk,
       sr.sr_return_amt,
       sr.sr_return_tax,
       sr_time.t_hour AS return_hour,
       sr_time.t_sub_shift AS return_shift,
       CASE
           WHEN sr.sr_return_amt > cs.cs_ext_sales_price * 0.5 THEN 'High Return'
           ELSE 'Low Return'
       END AS return_severity
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN time_dim cs_time ON cs.cs_sold_time_sk = cs_time.t_time_sk
   JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
   JOIN time_dim sr_time ON sr.sr_return_time_sk = sr_time.t_time_sk
   WHERE i.i_category = 'furniture'
     AND i.i_manager_id IN (13, 63)
     AND cs.cs_ext_sales_price > 100
     AND sr.sr_return_amt > 50
     AND cs_time.t_sub_shift = 'morning'
     AND sr_time.t_sub_shift = 'afternoon'
)
SELECT
    b.cs_sold_date_sk,
    b.cs_item_sk,
    b.i_category,
    b.i_manager_id,
    b.cs_ext_sales_price,
    b.cs_quantity,
    b.sold_hour,
    b.sold_shift,
    b.sr_return_amt,
    b.return_severity,
    RANK() OVER (PARTITION BY b.i_category ORDER BY b.cs_ext_sales_price DESC) AS category_price_rank,
    ROW_NUMBER() OVER (PARTITION BY b.i_manager_id ORDER BY b.cs_ext_sales_price DESC) AS manager_price_rownum,
    lt.total_distinct_return_amt
FROM base b
CROSS JOIN LATERAL (
    SELECT SUM(d.distinct_return_amt) AS total_distinct_return_amt
    FROM (
        SELECT DISTINCT sr2.sr_return_amt AS distinct_return_amt
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = b.cs_item_sk
    ) d
) lt
WHERE b.return_severity = 'High Return'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr3
        WHERE sr3.sr_item_sk = b.cs_item_sk
          AND sr3.sr_returned_date_sk = b.cs_sold_date_sk
  )
ORDER BY b.i_category, category_price_rank
LIMIT 100
