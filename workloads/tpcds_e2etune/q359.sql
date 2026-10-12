WITH catalog_monthly AS (
  SELECT d.d_year,
         d.d_moy,
         cp.cp_department,
         SUM(cs.cs_net_profit) AS catalog_net_profit,
         SUM(cs.cs_ext_discount_amt) AS catalog_total_discount
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
    AND cp.cp_type = 'Catalog'
  GROUP BY d.d_year, d.d_moy, cp.cp_department
),
web_monthly AS (
  SELECT d.d_year,
         d.d_moy,
         wp.wp_type,
         SUM(ws.ws_net_profit) AS web_net_profit,
         SUM(ws.ws_ext_discount_amt) AS web_total_discount
  FROM web_sales ws
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
    AND wp.wp_type = 'Content'
  GROUP BY d.d_year, d.d_moy, wp.wp_type
),
returns_monthly AS (
  SELECT d.d_year,
         d.d_moy,
         SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
         COUNT(*) AS return_cnt
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
    AND r.r_reason_id <> 'R001'
  GROUP BY d.d_year, d.d_moy
),
combined AS (
  SELECT cm.d_year,
         cm.d_moy,
         'catalog' AS channel,
         cm.cp_department AS group_key,
         cm.catalog_net_profit,
         0.0 AS web_net_profit,
         rm.total_return_amount
  FROM catalog_monthly cm
  LEFT JOIN returns_monthly rm ON cm.d_year = rm.d_year AND cm.d_moy = rm.d_moy
  UNION ALL
  SELECT wm.d_year,
         wm.d_moy,
         'web' AS channel,
         wm.wp_type AS group_key,
         0.0 AS catalog_net_profit,
         wm.web_net_profit,
         rm.total_return_amount
  FROM web_monthly wm
  LEFT JOIN returns_monthly rm ON wm.d_year = rm.d_year AND wm.d_moy = rm.d_moy
)
SELECT c.d_year,
       c.d_moy,
       c.channel,
       c.group_key,
       c.catalog_net_profit + c.web_net_profit AS net_profit,
       c.total_return_amount,
       (c.catalog_net_profit + c.web_net_profit - COALESCE(c.total_return_amount, 0)) AS net_profit_after_returns,
       RANK() OVER (PARTITION BY c.d_year, c.d_moy ORDER BY (c.catalog_net_profit + c.web_net_profit - COALESCE(c.total_return_amount, 0)) DESC) AS profit_rank
FROM combined c
WHERE (c.catalog_net_profit + c.web_net_profit) > 0
ORDER BY c.d_year, c.d_moy, profit_rank
LIMIT 100
