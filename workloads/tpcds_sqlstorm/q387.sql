WITH
store_sales_agg AS (
 SELECT
   'store' AS channel,
   i.i_category AS category,
   cd.cd_gender AS gender,
   d.d_year AS year,
   s.s_state AS state,
   SUM(ss.ss_net_profit) AS total_net_profit,
   SUM(ss.ss_net_paid) AS total_net_paid,
   SUM(p.p_cost) AS total_promo_cost,
   COUNT(*) AS txn_count
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
 JOIN store s ON ss.ss_store_sk = s.s_store_sk
 LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
 GROUP BY i.i_category, cd.cd_gender, d.d_year, s.s_state
),
catalog_sales_agg AS (
 SELECT
   'catalog' AS channel,
   i.i_category AS category,
   cd.cd_gender AS gender,
   d.d_year AS year,
   cc.cc_state AS state,
   SUM(cs.cs_net_profit) AS total_net_profit,
   SUM(cs.cs_net_paid) AS total_net_paid,
   SUM(p.p_cost) AS total_promo_cost,
   COUNT(*) AS txn_count
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
 JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
 LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
 GROUP BY i.i_category, cd.cd_gender, d.d_year, cc.cc_state
),
web_sales_agg AS (
 SELECT
   'web' AS channel,
   i.i_category AS category,
   cd.cd_gender AS gender,
   d.d_year AS year,
   w.web_state AS state,
   SUM(ws.ws_net_profit) AS total_net_profit,
   SUM(ws.ws_net_paid) AS total_net_paid,
   SUM(p.p_cost) AS total_promo_cost,
   COUNT(*) AS txn_count
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
 JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
 LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
 GROUP BY i.i_category, cd.cd_gender, d.d_year, w.web_state
),
combined AS (
 SELECT * FROM store_sales_agg
 UNION ALL
 SELECT * FROM catalog_sales_agg
 UNION ALL
 SELECT * FROM web_sales_agg
)
SELECT
  channel,
  category,
  gender,
  year,
  state,
  total_net_profit,
  total_net_paid,
  txn_count,
  ROUND(total_net_profit / NULLIF(total_net_paid, 0), 4) AS profit_margin,
  total_promo_cost,
  ROUND(total_promo_cost / NULLIF(total_net_profit, 0), 4) AS promo_cost_per_profit,
  AVG(total_net_profit) OVER (PARTITION BY channel, category, gender, state ORDER BY year ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS profit_ma4,
  total_net_profit - LAG(total_net_profit) OVER (PARTITION BY channel, category, gender, state ORDER BY year) AS yoy_profit_change
FROM combined
WHERE year >= (SELECT MAX(d_year) - 5 FROM date_dim)
ORDER BY total_net_profit DESC
LIMIT 100
