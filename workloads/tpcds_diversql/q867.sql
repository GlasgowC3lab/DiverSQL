/*
  Goal: Compare yearly profit contributions from web sales and catalog returns for warehouses that appear in both data sets, 
  applying regex filters on customer email and warehouse city, using string functions, UNION, INTERSECT, GROUPING SETS, and paging.
*/
WITH
  -- Web sales profit per year and warehouse (with regex filters on customer email and street type)
  ws AS (
    SELECT
      d.d_year,
      w.w_warehouse_sk,
      w.w_city,
      SUM(ws.ws_net_profit) AS profit
    FROM
      web_sales ws
      INNER JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
      INNER JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
      INNER JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
      regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
      AND w.w_street_type LIKE 'R%'
    GROUP BY
      GROUPING SETS (
        (d.d_year, w.w_city, w.w_warehouse_sk),
        (d.d_year, w.w_warehouse_sk)
      )
  ),
  -- Catalog returns loss (treated as negative profit) per year and warehouse (regex on city and street type)
  cr AS (
    SELECT
      d.d_year,
      w.w_warehouse_sk,
      w.w_city,
      -SUM(cr.cr_net_loss) AS profit
    FROM
      catalog_returns cr
      INNER JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
      INNER JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE
      regexp_like(w.w_city, '^New.*')
      AND w.w_street_type LIKE '%t'
    GROUP BY
      GROUPING SETS (
        (d.d_year, w.w_city, w.w_warehouse_sk),
        (d.d_year, w.w_warehouse_sk)
      )
  ),
  -- Union the two profit sources (distinct rows)
  union_data AS (
    SELECT d_year, w_warehouse_sk, w_city, profit FROM ws
    UNION
    SELECT d_year, w_warehouse_sk, w_city, profit FROM cr
  ),
  -- Warehouses that appear in BOTH web sales and catalog returns
  common_warehouses AS (
    SELECT w_warehouse_sk FROM ws
    INTERSECT
    SELECT w_warehouse_sk FROM cr
  )
SELECT
  ud.d_year,
  ud.w_city,
  CONCAT(ud.w_city, '-', CAST(ud.d_year AS VARCHAR)) AS city_year_key,
  SUM(ud.profit) AS total_profit
FROM
  union_data ud
  INNER JOIN common_warehouses cw ON ud.w_warehouse_sk = cw.w_warehouse_sk
GROUP BY
  ud.d_year,
  ud.w_city,
  CONCAT(ud.w_city, '-', CAST(ud.d_year AS VARCHAR))
ORDER BY
  total_profit DESC
OFFSET 0 LIMIT 100
