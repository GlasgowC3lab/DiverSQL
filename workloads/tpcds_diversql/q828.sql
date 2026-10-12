WITH cat_sales AS (
   SELECT i.i_item_id,
          SUM(cs.cs_ext_sales_price) AS total_sales,
          COUNT(*) AS sales_cnt
   FROM catalog_sales cs
   TABLESAMPLE BERNOULLI (10)
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE cs.cs_sold_date_sk BETWEEN 2451178 AND 2451821
   GROUP BY GROUPING SETS ((i.i_item_id), ())
),
web_sales AS (
   SELECT i.i_item_id,
          SUM(ws.ws_ext_sales_price) AS total_sales,
          COUNT(*) AS sales_cnt
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE ws.ws_sold_date_sk BETWEEN 2451178 AND 2451821
   GROUP BY GROUPING SETS ((i.i_item_id), ())
),
combined AS (
   SELECT i_item_id, total_sales, sales_cnt FROM cat_sales
   UNION ALL
   SELECT i_item_id, total_sales, sales_cnt FROM web_sales
),
filtered AS (
   SELECT i_item_id,
          SUM(total_sales) AS agg_sales,
          SUM(sales_cnt) AS agg_cnt
   FROM combined
   WHERE total_sales > 1000
   GROUP BY i_item_id
),
high_inventory AS (
   SELECT i.i_item_id
   FROM inventory inv
   JOIN item i ON inv.inv_item_sk = i.i_item_sk
   WHERE inv.inv_quantity_on_hand > 500
   GROUP BY i.i_item_id
)
SELECT f.i_item_id,
       f.agg_sales,
       f.agg_cnt,
       r.return_cnt,
       (SELECT MAX(c.cs_wholesale_cost) FROM catalog_sales c WHERE c.cs_item_sk = i.i_item_sk) AS max_wholesale_cost
FROM filtered f
JOIN item i ON i.i_item_id = f.i_item_id
CROSS JOIN LATERAL (
   SELECT COUNT(*) AS return_cnt
   FROM catalog_returns cr
   WHERE cr.cr_item_sk = i.i_item_sk
) AS r
WHERE EXISTS (SELECT 1 FROM high_inventory hi WHERE hi.i_item_id = f.i_item_id)
INTERSECT
SELECT f2.i_item_id,
       f2.agg_sales,
       f2.agg_cnt,
       r2.return_cnt,
       (SELECT MAX(c.cs_wholesale_cost) FROM catalog_sales c WHERE c.cs_item_sk = i2.i_item_sk) AS max_wholesale_cost
FROM filtered f2
JOIN item i2 ON i2.i_item_id = f2.i_item_id
CROSS JOIN LATERAL (
   SELECT COUNT(*) AS return_cnt
   FROM catalog_returns cr
   WHERE cr.cr_item_sk = i2.i_item_sk
) AS r2
WHERE f2.agg_sales > 5000
ORDER BY agg_sales DESC
LIMIT 100
