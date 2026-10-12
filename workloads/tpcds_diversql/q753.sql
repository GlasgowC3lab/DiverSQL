WITH sampled_catalog_sales AS (
  SELECT *
  FROM catalog_sales
  TABLESAMPLE BERNOULLI (10)
),
aggregated_data AS (
  SELECT
    d1.d_year AS sold_year,
    cp.cp_department,
    wsite.web_name,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt
  FROM sampled_catalog_sales cs
  JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
  JOIN date_dim d2 ON cs.cs_ship_date_sk = d2.d_date_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = cs.cs_item_sk
  JOIN date_dim d3 ON cr.cr_returned_date_sk = d3.d_date_sk
  JOIN catalog_page cp2 ON cr.cr_catalog_page_sk = cp2.cp_catalog_page_sk
  JOIN web_sales ws ON ws.ws_order_number = cs.cs_order_number AND ws.ws_item_sk = cs.cs_item_sk
  JOIN date_dim d4 ON ws.ws_sold_date_sk = d4.d_date_sk
  JOIN date_dim d5 ON ws.ws_ship_date_sk = d5.d_date_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
  JOIN date_dim d6 ON wr.wr_returned_date_sk = d6.d_date_sk
  JOIN web_page wp2 ON wr.wr_web_page_sk = wp2.wp_web_page_sk
  CROSS JOIN (SELECT 1 AS flag UNION ALL SELECT 2 AS flag) flags
  WHERE cs.cs_order_number IN (
    SELECT order_num FROM (
      SELECT cs_inner.cs_order_number AS order_num
      FROM catalog_sales cs_inner
      WHERE cs_inner.cs_quantity > 5
      INTERSECT
      SELECT ws_inner.ws_order_number AS order_num
      FROM web_sales ws_inner
      WHERE ws_inner.ws_quantity > 5
    )
  )
  AND cs.cs_order_number NOT IN (
    SELECT wr2.wr_order_number
    FROM web_returns wr2
    WHERE wr2.wr_return_quantity > 0
  )
  GROUP BY
    d1.d_year,
    cp.cp_department,
    wsite.web_name,
    flags.flag
)
SELECT
  sold_year,
  cp_department,
  web_name,
  total_net_paid,
  total_return_amount,
  order_cnt,
  ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_net_paid DESC) AS dept_rank
FROM aggregated_data
ORDER BY total_net_paid DESC
LIMIT 100
