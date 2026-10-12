WITH store_sales_agg AS (
  SELECT
    i.i_category AS category,
    cd.cd_gender AS gender,
    cd.cd_marital_status AS marital_status,
    SUM(ss.ss_net_paid) AS store_net_paid,
    SUM(ss.ss_ext_discount_amt) AS store_discount,
    SUM(ss.ss_net_profit) AS store_net_profit,
    COUNT(*) AS store_transactions
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  WHERE ss.ss_sold_date_sk BETWEEN 2450800 AND 2451100
  GROUP BY i.i_category, cd.cd_gender, cd.cd_marital_status
),
web_sales_agg AS (
  SELECT
    i.i_category AS category,
    cd.cd_gender AS gender,
    cd.cd_marital_status AS marital_status,
    sm.sm_type AS ship_mode,
    ws.ws_web_site_sk AS web_site_sk,
    SUM(ws.ws_net_paid) AS web_net_paid,
    SUM(ws.ws_ext_discount_amt) AS web_discount,
    SUM(ws.ws_net_profit) AS web_net_profit,
    COUNT(*) AS web_transactions
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450800 AND 2451100
    AND wsite.web_state = 'CA'
  GROUP BY i.i_category, cd.cd_gender, cd.cd_marital_status, sm.sm_type, ws.ws_web_site_sk
),
combined AS (
  SELECT
    s.category,
    s.gender,
    s.marital_status,
    NULL AS ship_mode,
    NULL AS web_site_sk,
    s.store_net_paid,
    s.store_discount,
    s.store_net_profit,
    s.store_transactions,
    0 AS web_net_paid,
    0 AS web_discount,
    0 AS web_net_profit,
    0 AS web_transactions
  FROM store_sales_agg s
  UNION ALL
  SELECT
    w.category,
    w.gender,
    w.marital_status,
    w.ship_mode,
    w.web_site_sk,
    0,
    0,
    0,
    0,
    w.web_net_paid,
    w.web_discount,
    w.web_net_profit,
    w.web_transactions
  FROM web_sales_agg w
)
SELECT
  category,
  gender,
  marital_status,
  ship_mode,
  SUM(store_net_paid) + SUM(web_net_paid) AS total_net_paid,
  (SUM(store_discount) + SUM(web_discount)) / NULLIF(SUM(store_transactions) + SUM(web_transactions), 0) AS avg_discount_per_txn,
  SUM(store_net_profit) + SUM(web_net_profit) AS total_net_profit,
  SUM(store_transactions) + SUM(web_transactions) AS total_transactions,
  RANK() OVER (ORDER BY SUM(store_net_profit) + SUM(web_net_profit) DESC) AS profit_rank
FROM combined
GROUP BY category, gender, marital_status, ship_mode
HAVING SUM(store_net_profit) + SUM(web_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 50
