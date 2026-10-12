WITH catalog_agg AS (
  SELECT cp.cp_department AS department,
         sm.sm_type AS ship_mode,
         SUM(cs.cs_net_profit) AS catalog_net_profit,
         SUM(cs.cs_quantity) AS catalog_quantity,
         AVG(cs.cs_ext_discount_amt) AS avg_catalog_discount
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
    AND cd.cd_gender = 'F'
  GROUP BY cp.cp_department, sm.sm_type
),
web_agg AS (
  SELECT wp.wp_type AS web_page_type,
         sm.sm_type AS ship_mode,
         SUM(ws.ws_net_profit) AS web_net_profit,
         SUM(ws.ws_quantity) AS web_quantity,
         AVG(ws.ws_ext_discount_amt) AS avg_web_discount
  FROM web_sales ws
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
    AND cd.cd_gender = 'F'
  GROUP BY wp.wp_type, sm.sm_type
)
SELECT ca.department,
       ca.ship_mode,
       ca.catalog_net_profit,
       wa.web_net_profit,
       (ca.catalog_net_profit + wa.web_net_profit) AS total_net_profit,
       (ca.catalog_quantity + wa.web_quantity) AS total_quantity,
       (ca.avg_catalog_discount + wa.avg_web_discount) / 2 AS avg_discount,
       RANK() OVER (PARTITION BY ca.department ORDER BY (ca.catalog_net_profit + wa.web_net_profit) DESC) AS profit_rank
FROM catalog_agg ca
JOIN web_agg wa ON ca.ship_mode = wa.ship_mode
WHERE ca.catalog_net_profit > 0
  AND wa.web_net_profit > 0
ORDER BY ca.department, profit_rank
LIMIT 20
