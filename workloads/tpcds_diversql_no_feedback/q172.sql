WITH sales AS (
    SELECT
        d.d_date AS trans_date,
        i.i_item_id,
        i.i_product_name,
        cs.cs_ext_sales_price AS amount,
        'SALE' AS src
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2002
      AND i.i_brand = 'BrandX'
      AND cs.cs_item_sk IN (
          SELECT i2.i_item_sk
          FROM item i2
          WHERE i2.i_category = 'Electronics'
      )
),
returns AS (
    SELECT
        d.d_date AS trans_date,
        i.i_item_id,
        i.i_product_name,
        sr.sr_return_amt AS amount,
        'RETURN' AS src
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
      AND i.i_category = 'Electronics'
)
SELECT trans_date, i_item_id, i_product_name, amount, src
FROM sales
UNION ALL
SELECT trans_date, i_item_id, i_product_name, amount, src
FROM returns
ORDER BY amount DESC, trans_date ASC
LIMIT 100
