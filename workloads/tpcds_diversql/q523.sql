WITH
  catalog_sales_agg AS (
    SELECT
      d.d_date AS sales_date,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      SUM(cs.cs_ext_tax) AS total_tax,
      CASE WHEN SUM(cs.cs_quantity) > 100 THEN 'HighQty' ELSE 'LowQty' END AS qty_category,
      ws.web_state
    FROM
      catalog_sales cs
      TABLESAMPLE BERNOULLI (10)
      JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
      JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
      JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
      JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE
      d.d_year = 2001
      AND cc.cc_employees > 500000
      AND cp.cp_description LIKE '%sales%'
      AND ws.web_state = 'CA'
    GROUP BY
      d.d_date,
      ws.web_state
  ),

  store_sales_agg AS (
    SELECT
      d.d_date AS sales_date,
      SUM(ss.ss_ext_sales_price) AS total_store_sales,
      SUM(ss.ss_ext_tax) AS total_store_tax,
      CASE WHEN SUM(ss.ss_quantity) > 200 THEN 'Big' ELSE 'Small' END AS store_qty_category
    FROM
      store_sales ss
      TABLESAMPLE BERNOULLI (10)
      JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE
      d.d_year = 2001
      AND ss.ss_ext_tax > 20
    GROUP BY
      d.d_date
  ),

  intersect_dates AS (
    SELECT sales_date FROM catalog_sales_agg WHERE total_sales > 10000
    INTERSECT
    SELECT sales_date FROM store_sales_agg WHERE total_store_sales > 15000
  ),

  catalog_returns_agg AS (
    SELECT
      d.d_date AS return_date,
      SUM(cr.cr_return_amount) AS total_cr_return
    FROM
      catalog_returns cr
      JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY
      d.d_date
  ),

  store_returns_agg AS (
    SELECT
      d.d_date AS return_date,
      SUM(sr.sr_return_amt) AS total_sr_return
    FROM
      store_returns sr
      JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY
      d.d_date
  ),

  full_returns AS (
    SELECT
      COALESCE(cr.return_date, sr.return_date) AS return_date,
      cr.total_cr_return,
      sr.total_sr_return
    FROM catalog_returns_agg cr
    FULL OUTER JOIN store_returns_agg sr
      ON cr.return_date = sr.return_date
  ),

  union_sales AS (
    SELECT sales_date, total_sales AS sales_amount FROM catalog_sales_agg
    UNION
    SELECT sales_date, total_store_sales AS sales_amount FROM store_sales_agg
  ),

  final_agg AS (
    SELECT
      u.sales_date,
      AVG(u.sales_amount) AS avg_sales_amount,
      COUNT(*) AS cnt_dates,
      SUM(fr.total_cr_return) AS sum_cr_return,
      SUM(fr.total_sr_return) AS sum_sr_return
    FROM union_sales u
    JOIN intersect_dates i ON u.sales_date = i.sales_date
    LEFT JOIN full_returns fr ON u.sales_date = fr.return_date
    GROUP BY u.sales_date
  )
SELECT
  sales_date,
  avg_sales_amount,
  cnt_dates,
  sum_cr_return,
  sum_sr_return
FROM final_agg
ORDER BY avg_sales_amount DESC
LIMIT 100
