WITH
combined_sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_quantity AS quantity,
           cs.cs_ext_sales_price AS sales,
           'catalog' AS sales_type
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_quantity,
           ss.ss_ext_sales_price,
           'store'
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_quantity,
           ws.ws_ext_sales_price,
           'web'
    FROM web_sales ws
),
combined_returns AS (
    SELECT cr.cr_returned_date_sk AS date_sk,
           cr.cr_item_sk AS item_sk,
           cr.cr_return_quantity AS quantity,
           cr.cr_return_amount AS returns,
           'catalog' AS return_type
    FROM catalog_returns cr
    UNION ALL
    SELECT sr.sr_returned_date_sk,
           sr.sr_item_sk,
           sr.sr_return_quantity,
           sr.sr_return_amt,
           'store'
    FROM store_returns sr
    UNION ALL
    SELECT wr.wr_returned_date_sk,
           wr.wr_item_sk,
           wr.wr_return_quantity,
           wr.wr_return_amt,
           'web'
    FROM web_returns wr
)
SELECT d.d_year,
       s.sales_type,
       i.i_category,
       i.i_class,
       SUM(s.sales) AS total_sales,
       SUM(r.returns) AS total_returns,
       SUM(s.sales) - COALESCE(SUM(r.returns), 0) AS net_sales,
       AVG(s.sales / s.quantity) AS avg_price,
       SUM(s.quantity) AS total_quantity,
       COUNT(DISTINCT s.item_sk) AS distinct_items
FROM combined_sales s
LEFT JOIN combined_returns r
  ON s.date_sk = r.date_sk
  AND s.item_sk = r.item_sk
  AND s.sales_type = r.return_type
JOIN date_dim d ON s.date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
WHERE d.d_year = 2002
GROUP BY d.d_year, s.sales_type, i.i_category, i.i_class
ORDER BY total_sales DESC
LIMIT 50
