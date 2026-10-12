WITH
  catalog_agg AS (
    SELECT
      cp.cp_department AS department,
      td.t_hour AS hour,
      SUM(cs.cs_net_profit) AS profit,
      SUM(cs.cs_quantity) AS quantity,
      SUM(cs.cs_ext_sales_price) AS sales,
      SUM(u.val) AS unnested_sum
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN LATERAL (
      SELECT ARRAY[CAST(cs.cs_quantity AS DOUBLE), CAST(cs.cs_ext_discount_amt AS DOUBLE)] AS arr
    ) l ON TRUE
    LEFT JOIN UNNEST(l.arr) AS u(val) ON TRUE
    GROUP BY ROLLUP (cp.cp_department, td.t_hour)
  ),
  web_agg AS (
    SELECT
      CAST('Web' AS VARCHAR) AS department,
      td.t_hour AS hour,
      SUM(ws.ws_net_profit) AS profit,
      SUM(ws.ws_quantity) AS quantity,
      SUM(ws.ws_ext_sales_price) AS sales,
      SUM(u.val) AS unnested_sum
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN LATERAL (
      SELECT ARRAY[CAST(ws.ws_quantity AS DOUBLE), CAST(ws.ws_ext_discount_amt AS DOUBLE)] AS arr
    ) l ON TRUE
    LEFT JOIN UNNEST(l.arr) AS u(val) ON TRUE
    GROUP BY ROLLUP (td.t_hour)
  ),
  sales_all AS (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
  ),
  promo_sales AS (
    SELECT
      cp.cp_department AS department,
      td.t_hour AS hour,
      SUM(cs.cs_net_profit) AS profit,
      SUM(cs.cs_quantity) AS quantity,
      SUM(cs.cs_ext_sales_price) AS sales,
      SUM(u.val) AS unnested_sum
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN LATERAL (
      SELECT ARRAY[CAST(cs.cs_quantity AS DOUBLE), CAST(cs.cs_ext_discount_amt AS DOUBLE)] AS arr
    ) l ON TRUE
    LEFT JOIN UNNEST(l.arr) AS u(val) ON TRUE
    WHERE p.p_discount_active = 'Y'
    GROUP BY ROLLUP (cp.cp_department, td.t_hour)
  )
SELECT
  department,
  hour,
  profit,
  quantity,
  sales,
  unnested_sum
FROM sales_all
EXCEPT
SELECT
  department,
  hour,
  profit,
  quantity,
  sales,
  unnested_sum
FROM promo_sales
ORDER BY department ASC NULLS LAST, hour
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
