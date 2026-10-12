WITH sales_data AS (
  SELECT d.d_year AS yr,
         s.s_country AS country,
         SUM(ss.ss_net_profit) AS profit,
         CAST(0 AS decimal(7,2)) AS loss
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  GROUP BY d.d_year, s.s_country
  UNION ALL
  SELECT d.d_year,
         c.cc_country,
         SUM(cs.cs_net_profit),
         CAST(0 AS decimal(7,2))
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center c ON cs.cs_call_center_sk = c.cc_call_center_sk
  GROUP BY d.d_year, c.cc_country
  UNION ALL
  SELECT d.d_year,
         w.web_country,
         SUM(ws.ws_net_profit),
         CAST(0 AS decimal(7,2))
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
  GROUP BY d.d_year, w.web_country
  UNION ALL
  SELECT d.d_year,
         s.s_country,
         CAST(0 AS decimal(7,2)),
         SUM(sr.sr_net_loss)
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  GROUP BY d.d_year, s.s_country
  UNION ALL
  SELECT d.d_year,
         c.cc_country,
         CAST(0 AS decimal(7,2)),
         SUM(cr.cr_net_loss)
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN call_center c ON cr.cr_call_center_sk = c.cc_call_center_sk
  GROUP BY d.d_year, c.cc_country
  UNION ALL
  SELECT d.d_year,
         'UNKNOWN' AS country,
         CAST(0 AS decimal(7,2)),
         SUM(wr.wr_net_loss)
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  GROUP BY d.d_year
)
SELECT yr,
       country,
       SUM(profit) AS total_sales_profit,
       SUM(loss) AS total_returns_loss,
       SUM(profit) - SUM(loss) AS net_profit
FROM sales_data
GROUP BY yr, country
ORDER BY yr, country
