WITH sales_cust AS (
  SELECT
    ws.ws_web_site_sk,
    ws.ws_bill_cdemo_sk,
    ws.ws_quantity,
    ws.ws_net_paid,
    ws.ws_net_profit,
    cd.cd_demo_sk,
    cd.cd_education_status,
    cd.cd_dep_count,
    cd.cd_purchase_estimate
  FROM web_sales ws
  RIGHT OUTER JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  WHERE cd.cd_education_status = 'College'
    AND cd.cd_dep_count >= 2
    AND cd.cd_purchase_estimate BETWEEN 2000 AND 8000
    AND ws.ws_quantity > 1
    AND ws.ws_net_paid > 100.00
),
ranked AS (
  SELECT
    ws_site.web_state,
    sc.cd_education_status,
    COUNT(sc.cd_demo_sk) AS demo_cnt,
    SUM(sc.ws_net_paid) AS total_net_paid,
    AVG(sc.ws_net_profit) AS avg_profit,
    MIN(sc.ws_net_paid) AS min_net_paid,
    MAX(sc.ws_net_paid) AS max_net_paid,
    ROW_NUMBER() OVER (PARTITION BY ws_site.web_state ORDER BY SUM(sc.ws_net_paid) DESC) AS rn
  FROM sales_cust sc
  RIGHT OUTER JOIN web_site ws_site
    ON sc.ws_web_site_sk = ws_site.web_site_sk
  WHERE ws_site.web_gmt_offset = -5.00
    AND ws_site.web_market_manager = 'James Bernard'
    AND ws_site.web_rec_end_date = DATE '2001-08-15'
  GROUP BY ws_site.web_state, sc.cd_education_status
)
SELECT
  web_state,
  cd_education_status,
  demo_cnt,
  total_net_paid,
  avg_profit,
  min_net_paid,
  max_net_paid,
  rn
FROM ranked
WHERE rn <= 3
ORDER BY web_state, rn
LIMIT 100
