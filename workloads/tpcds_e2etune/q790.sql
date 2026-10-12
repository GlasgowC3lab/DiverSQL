SELECT
  t.warehouse_state,
  t.promo_purpose,
  t.orders,
  t.total_net_paid,
  t.total_net_profit,
  t.avg_discount,
  t.profit_rank
FROM (
   SELECT
     w.w_state AS warehouse_state,
     p.p_purpose AS promo_purpose,
     COUNT(DISTINCT ws.ws_order_number) AS orders,
     SUM(ws.ws_net_paid) AS total_net_paid,
     SUM(ws.ws_net_profit) AS total_net_profit,
     AVG(ws.ws_ext_discount_amt) AS avg_discount,
     RANK() OVER (PARTITION BY w.w_state ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
   FROM web_sales ws
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451900
     AND p.p_discount_active = 'Y'
     AND w.w_country = 'United States'
   GROUP BY w.w_state, p.p_purpose
   HAVING SUM(ws.ws_net_profit) > 1000
) t
WHERE t.profit_rank <= 5
ORDER BY t.total_net_profit DESC
LIMIT 10
