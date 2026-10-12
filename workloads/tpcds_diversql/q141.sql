WITH
  sales_agg AS (
    SELECT
      d.d_year,
      i.i_category,
      SUM(cs.cs_net_paid) AS amount,
      'sale' AS txn_type
    FROM
      catalog_sales cs
      JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
      JOIN item i TABLESAMPLE BERNOULLI (20) ON cs.cs_item_sk = i.i_item_sk
      JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
      JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
      JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE
      d.d_year = 2001
      AND i.i_units = 'Lb'
    GROUP BY
      d.d_year,
      i.i_category
  ),
  returns_agg AS (
    SELECT
      d.d_year,
      i.i_category,
      SUM(cr.cr_return_amount) AS amount,
      'return' AS txn_type
    FROM
      catalog_returns cr
      JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
      JOIN item i TABLESAMPLE BERNOULLI (20) ON cr.cr_item_sk = i.i_item_sk
      JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
      JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE
      d.d_year = 2001
      AND cr.cr_return_amount > 0
    GROUP BY
      d.d_year,
      i.i_category
  ),
  combined AS (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM returns_agg
  )
SELECT
  ROW_NUMBER() OVER (PARTITION BY txn_type ORDER BY amount DESC) AS rn,
  d_year,
  i_category,
  amount,
  txn_type
FROM combined
ORDER BY amount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
