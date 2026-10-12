WITH store_sales_agg AS (
  SELECT d.d_year,
         i.i_category,
         i.i_class,
         i.i_brand,
         s.s_state AS store_state,
         SUM(ss.ss_net_profit) AS store_net_profit,
         SUM(ss.ss_quantity) AS store_quantity
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  GROUP BY d.d_year, i.i_category, i.i_class, i.i_brand, s.s_state
),
web_sales_agg AS (
  SELECT d.d_year,
         i.i_category,
         i.i_class,
         i.i_brand,
         w.web_state AS web_state,
         SUM(ws.ws_net_profit) AS web_net_profit,
         SUM(ws.ws_quantity) AS web_quantity
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
  GROUP BY d.d_year, i.i_category, i.i_class, i.i_brand, w.web_state
),
catalog_sales_agg AS (
  SELECT d.d_year,
         i.i_category,
         i.i_class,
         i.i_brand,
         cc.cc_state AS catalog_state,
         SUM(cs.cs_net_profit) AS catalog_net_profit,
         SUM(cs.cs_quantity) AS catalog_quantity
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  GROUP BY d.d_year, i.i_category, i.i_class, i.i_brand, cc.cc_state
),
returns_agg AS (
  SELECT d.d_year,
         i.i_category,
         i.i_class,
         i.i_brand,
         SUM(cr.cr_net_loss) AS total_return_loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_category, i.i_class, i.i_brand
  UNION ALL
  SELECT d.d_year,
         i.i_category,
         i.i_class,
         i.i_brand,
         SUM(sr.sr_net_loss) AS total_return_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_category, i.i_class, i.i_brand
  UNION ALL
  SELECT d.d_year,
         i.i_category,
         i.i_class,
         i.i_brand,
         SUM(wr.wr_net_loss) AS total_return_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_category, i.i_class, i.i_brand
),
combined AS (
  SELECT COALESCE(ss.d_year, ws.d_year, cs.d_year) AS year,
         COALESCE(ss.i_category, ws.i_category, cs.i_category) AS category,
         COALESCE(ss.i_class, ws.i_class, cs.i_class) AS class,
         COALESCE(ss.i_brand, ws.i_brand, cs.i_brand) AS brand,
         ss.store_state,
         ws.web_state,
         cs.catalog_state,
         ss.store_net_profit,
         ss.store_quantity,
         ws.web_net_profit,
         ws.web_quantity,
         cs.catalog_net_profit,
         cs.catalog_quantity,
         COALESCE(r.total_return_loss, 0) AS total_return_loss
  FROM store_sales_agg ss
  FULL OUTER JOIN web_sales_agg ws
    ON ss.d_year = ws.d_year
   AND ss.i_category = ws.i_category
   AND ss.i_class = ws.i_class
   AND ss.i_brand = ws.i_brand
  FULL OUTER JOIN catalog_sales_agg cs
    ON COALESCE(ss.d_year, ws.d_year) = cs.d_year
   AND COALESCE(ss.i_category, ws.i_category) = cs.i_category
   AND COALESCE(ss.i_class, ws.i_class) = cs.i_class
   AND COALESCE(ss.i_brand, ws.i_brand) = cs.i_brand
  LEFT JOIN returns_agg r
    ON COALESCE(ss.d_year, ws.d_year, cs.d_year) = r.d_year
   AND COALESCE(ss.i_category, ws.i_category, cs.i_category) = r.i_category
   AND COALESCE(ss.i_class, ws.i_class, cs.i_class) = r.i_class
   AND COALESCE(ss.i_brand, ws.i_brand, cs.i_brand) = r.i_brand
)
SELECT year,
       category,
       class,
       brand,
       store_state,
       web_state,
       catalog_state,
       COALESCE(store_net_profit, 0) + COALESCE(web_net_profit, 0) + COALESCE(catalog_net_profit, 0) - total_return_loss AS net_profit,
       COALESCE(store_quantity, 0) + COALESCE(web_quantity, 0) + COALESCE(catalog_quantity, 0) AS total_quantity,
       ROUND(
         (COALESCE(store_net_profit, 0) + COALESCE(web_net_profit, 0) + COALESCE(catalog_net_profit, 0) - total_return_loss) /
         NULLIF((COALESCE(store_quantity, 0) + COALESCE(web_quantity, 0) + COALESCE(catalog_quantity, 0)), 0),
         2
       ) AS profit_per_unit,
       DENSE_RANK() OVER (PARTITION BY year ORDER BY (COALESCE(store_net_profit, 0) + COALESCE(web_net_profit, 0) + COALESCE(catalog_net_profit, 0) - total_return_loss) DESC) AS profit_rank
FROM combined
WHERE year IS NOT NULL
ORDER BY year, profit_rank
