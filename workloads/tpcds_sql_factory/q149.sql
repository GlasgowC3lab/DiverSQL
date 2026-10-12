SELECT p.p_promo_id,
       p.p_promo_name,
       sm.sm_type AS ship_mode_type,
       p.p_discount_active,
       SUM(cs.cs_net_paid) AS catalog_net_paid,
       SUM(ws.ws_net_paid) AS web_net_paid,
       (SUM(cs.cs_net_paid) + SUM(ws.ws_net_paid)) AS total_net_paid,
       SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) AS total_net_profit,
       PERCENT_RANK() OVER (ORDER BY (SUM(cs.cs_net_paid) + SUM(ws.ws_net_paid))) AS revenue_percentile
FROM promotion p
JOIN catalog_sales cs ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE p.p_start_date_sk >= 2450000   -- example filter on start date
GROUP BY p.p_promo_id, p.p_promo_name, sm.sm_type, p.p_discount_active
ORDER BY revenue_percentile DESC
LIMIT 20
