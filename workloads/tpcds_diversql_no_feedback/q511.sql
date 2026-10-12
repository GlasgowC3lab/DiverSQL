-- goal: compare total sales from catalog and web channels by year and item category, include subtotals and a grand total, and rank the results
WITH sales_union AS (
    SELECT
        d.d_year AS sales_year,
        i.i_category AS category,
        SUM(cs.cs_ext_sales_price) AS sales_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_quantity_on_hand > 0
            AND inv.inv_date_sk = d.d_date_sk
      )
    GROUP BY d.d_year, i.i_category

    UNION ALL

    SELECT
        d.d_year AS sales_year,
        i.i_category AS category,
        SUM(ws.ws_ext_sales_price) AS sales_amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_quantity_on_hand > 0
            AND inv.inv_date_sk = d.d_date_sk
      )
    GROUP BY d.d_year, i.i_category
)
SELECT
    COALESCE(sales_year, -1) AS sales_year,
    COALESCE(category, 'ALL') AS category,
    SUM(sales_amount) AS total_sales,
    (SELECT AVG(i_current_price) FROM item) AS avg_price,
    ROW_NUMBER() OVER (ORDER BY SUM(sales_amount) DESC) AS rn
FROM sales_union
GROUP BY ROLLUP (sales_year, category)
ORDER BY total_sales DESC
LIMIT 100
