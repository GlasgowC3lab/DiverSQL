WITH promo_agg AS (
   SELECT
      p.p_promo_sk,
      p.p_promo_id,
      p.p_promo_name,
      SUM(cs.cs_net_profit)               AS cs_profit,
      SUM(cs.cs_quantity)                 AS cs_qty,
      SUM(ss.ss_net_profit)               AS ss_profit,
      SUM(ss.ss_quantity)                 AS ss_qty,
      SUM(ws.ws_net_profit)               AS ws_profit,
      SUM(ws.ws_quantity)                 AS ws_qty,
      CASE WHEN SUM(cs.cs_net_profit + ss.ss_net_profit + ws.ws_net_profit) > 0
           THEN 'POSITIVE' ELSE 'NEGATIVE' END AS profit_indicator
   FROM catalog_sales cs
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
   JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
   JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
   JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
                     AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
                     AND ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
   JOIN inventory i TABLESAMPLE BERNOULLI (5) ON i.inv_warehouse_sk = w.w_warehouse_sk
   JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
   WHERE p.p_response_target = 1
     AND sm.sm_carrier = 'FEDEX'
     AND cd.cd_education_status = 'College'
     AND d_start.d_year = 2002
   GROUP BY p.p_promo_sk, p.p_promo_id, p.p_promo_name
   HAVING SUM(cs.cs_net_profit + ss.ss_net_profit + ws.ws_net_profit) > 10000
),
promo_agg_alt AS (
   SELECT
      p.p_promo_sk,
      p.p_promo_id,
      p.p_promo_name,
      SUM(cs.cs_net_profit)               AS cs_profit,
      SUM(cs.cs_quantity)                 AS cs_qty,
      SUM(ss.ss_net_profit)               AS ss_profit,
      SUM(ss.ss_quantity)                 AS ss_qty,
      SUM(ws.ws_net_profit)               AS ws_profit,
      SUM(ws.ws_quantity)                 AS ws_qty,
      CASE WHEN SUM(cs.cs_net_profit + ss.ss_net_profit + ws.ws_net_profit) > 0
           THEN 'POSITIVE' ELSE 'NEGATIVE' END AS profit_indicator
   FROM catalog_sales cs
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
   JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
   JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
   JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
                     AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
                     AND ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
   JOIN inventory i TABLESAMPLE BERNOULLI (5) ON i.inv_warehouse_sk = w.w_warehouse_sk
   JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
   WHERE p.p_response_target = 1
     AND sm.sm_carrier = 'FEDEX'
     AND cd.cd_education_status = 'College'
     AND d_end.d_year = 2002
   GROUP BY p.p_promo_sk, p.p_promo_id, p.p_promo_name
   HAVING SUM(cs.cs_net_profit + ss.ss_net_profit + ws.ws_net_profit) > 10000
)
SELECT
   promo_sk,
   promo_id,
   promo_name,
   total_profit,
   total_quantity,
   profit_indicator,
   RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM (
   SELECT
      p.p_promo_sk                     AS promo_sk,
      p.p_promo_id                     AS promo_id,
      p.p_promo_name                   AS promo_name,
      (p.cs_profit + p.ss_profit + p.ws_profit) AS total_profit,
      (p.cs_qty   + p.ss_qty   + p.ws_qty)     AS total_quantity,
      p.profit_indicator               AS profit_indicator
   FROM promo_agg p
   UNION
   SELECT
      p.p_promo_sk,
      p.p_promo_id,
      p.p_promo_name,
      (p.cs_profit + p.ss_profit + p.ws_profit),
      (p.cs_qty   + p.ss_qty   + p.ws_qty),
      p.profit_indicator
   FROM promo_agg_alt p
) combined
ORDER BY profit_rank
LIMIT 100
