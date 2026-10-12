/*
Goal: Identify recent sales that have not been returned (anti‑semi join) and returns of defective items for orders that were both preferred‑customer electronics sales and defective returns (INTERSECT). The query combines these two result sets with UNION ALL, applies DISTINCT, orders by net amount, and limits to 100 rows.
*/
WITH
  sales_pref AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND i.i_category = 'Electronics'
  ),
  returns_def AS (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%Defective%'
  ),
  intersect_orders AS (
    SELECT cs_order_number FROM sales_pref
    INTERSECT
    SELECT cr_order_number FROM returns_def
  ),
  anti_semi_orders AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_order_number NOT IN (
      SELECT cr.cr_order_number FROM catalog_returns cr
    )
  ),
  union_data AS (
    SELECT DISTINCT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_net_paid,
      'sale' AS src
    FROM catalog_sales cs
    JOIN anti_semi_orders aso ON cs.cs_order_number = aso.cs_order_number
    WHERE cs.cs_sold_date_sk BETWEEN 2451000 AND 2451100

    UNION ALL

    SELECT DISTINCT
      cr.cr_order_number AS cs_order_number,
      cr.cr_returned_date_sk AS cs_sold_date_sk,
      cr.cr_return_amount AS cs_net_paid,
      'return' AS src
    FROM catalog_returns cr
    JOIN intersect_orders io ON cr.cr_order_number = io.cs_order_number
    WHERE cr.cr_return_amount > 0
  )
SELECT
  ud.cs_order_number,
  ud.cs_sold_date_sk,
  ud.cs_net_paid,
  ud.src
FROM union_data ud
ORDER BY ud.cs_net_paid DESC
LIMIT 100
