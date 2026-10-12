WITH
  sales_agg AS (
    SELECT
      'sales' AS metric,
      i.i_category AS category,
      SUM(DISTINCT cs.cs_ext_sales_price) AS total_amount,
      COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_start_date_sk BETWEEN 2451271 AND 2451500
    GROUP BY i.i_category
  ),
  returns_agg AS (
    SELECT
      'returns' AS metric,
      i.i_category AS category,
      SUM(DISTINCT sr.sr_return_amt) AS total_amount,
      COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2451271 AND 2451500
    GROUP BY i.i_category
  )
SELECT metric,
       category,
       total_amount,
       distinct_customers
FROM sales_agg
UNION ALL
SELECT metric,
       category,
       total_amount,
       distinct_customers
FROM returns_agg
ORDER BY metric,
         total_amount DESC
LIMIT 100
