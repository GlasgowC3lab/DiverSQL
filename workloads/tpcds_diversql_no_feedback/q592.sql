WITH sales_by_meal AS (
  SELECT
    td.t_meal_time,
    i.i_category,
    COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_sales,
    COUNT(cs.cs_order_number) AS order_cnt,
    regexp_extract(i.i_product_name, '([A-Z]{3}[0-9]{2})') AS product_code
  FROM
    catalog_sales cs
    RIGHT JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE
    regexp_like(i.i_product_name, '[A-Z]{3}[0-9]{2}')
    AND i.i_color LIKE '%Blue%'
  GROUP BY
    td.t_meal_time,
    i.i_category,
    regexp_extract(i.i_product_name, '([A-Z]{3}[0-9]{2})')
),

inventory_sales AS (
  SELECT
    td.t_meal_time,
    i.i_category,
    COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_sales,
    COUNT(cs.cs_order_number) AS order_cnt,
    regexp_extract(i.i_product_name, '([A-Z]{3}[0-9]{2})') AS product_code
  FROM
    catalog_sales cs
    RIGHT JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
  WHERE
    i.i_product_name LIKE 'Magic%'
    AND inv.inv_quantity_on_hand > 0
    AND substring(i.i_product_name, 1, 3) = 'Mag'
  GROUP BY
    td.t_meal_time,
    i.i_category,
    regexp_extract(i.i_product_name, '([A-Z]{3}[0-9]{2})')
)
SELECT *
FROM sales_by_meal
UNION
SELECT *
FROM inventory_sales
ORDER BY total_sales DESC, order_cnt DESC
LIMIT 100
