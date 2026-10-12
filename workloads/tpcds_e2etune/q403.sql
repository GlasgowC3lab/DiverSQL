WITH store_agg AS (
  SELECT
    s.s_state AS state,
    cd.cd_education_status AS education,
    COUNT(DISTINCT ss.ss_customer_sk) AS store_unique_customers,
    SUM(ss.ss_net_profit) AS total_store_profit,
    AVG(ss.ss_net_profit) AS avg_store_profit,
    SUM(ss.ss_quantity) AS total_quantity,
    RANK() OVER (PARTITION BY cd.cd_education_status ORDER BY SUM(ss.ss_net_profit) DESC) AS state_rank
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  WHERE ss.ss_net_profit > 0
  GROUP BY s.s_state, cd.cd_education_status
),
web_agg AS (
  SELECT
    cd.cd_education_status AS education,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_unique_customers,
    SUM(ws.ws_net_profit) AS total_web_profit,
    AVG(ws.ws_net_profit) AS avg_web_profit,
    SUM(ws.ws_quantity) AS total_quantity
  FROM web_sales ws
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  WHERE ws.ws_net_profit > 0
  GROUP BY cd.cd_education_status
)
SELECT
  sa.state,
  sa.education,
  sa.total_store_profit,
  wa.total_web_profit,
  CASE WHEN wa.total_web_profit = 0 THEN NULL ELSE sa.total_store_profit / wa.total_web_profit END AS profit_ratio,
  sa.avg_store_profit,
  wa.avg_web_profit,
  sa.store_unique_customers,
  wa.web_unique_customers,
  sa.state_rank
FROM store_agg sa
LEFT JOIN web_agg wa ON sa.education = wa.education
WHERE sa.state_rank <= 5
ORDER BY profit_ratio DESC
LIMIT 25
