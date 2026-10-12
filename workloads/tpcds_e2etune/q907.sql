WITH return_agg AS (
   SELECT cp.cp_catalog_page_id,
          t.t_hour,
          SUM(cr.cr_return_amount) AS total_return_amount
   FROM catalog_returns cr
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
   WHERE cp.cp_department = 'DEPARTMENT'
     AND t.t_hour BETWEEN 9 AND 17
   GROUP BY cp.cp_catalog_page_id, t.t_hour
),
sales_agg AS (
   SELECT p.p_promo_id,
          t.t_hour,
          SUM(ws.ws_net_paid) AS total_sales_amount,
          SUM(ws.ws_net_profit) AS total_sales_profit,
          SUM(ws.ws_quantity) AS total_quantity_sold
   FROM web_sales ws
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   WHERE p.p_discount_active = 'Y'
     AND t.t_hour BETWEEN 9 AND 17
   GROUP BY p.p_promo_id, t.t_hour
)
SELECT ra.cp_catalog_page_id,
       sa.p_promo_id,
       ra.t_hour,
       ra.total_return_amount,
       sa.total_sales_amount,
       sa.total_sales_profit,
       sa.total_quantity_sold,
       CASE WHEN sa.total_sales_amount > 0 THEN ra.total_return_amount / sa.total_sales_amount END AS return_to_sales_ratio
FROM return_agg ra
JOIN sales_agg sa ON ra.t_hour = sa.t_hour
WHERE ra.total_return_amount > 0
ORDER BY return_to_sales_ratio DESC
LIMIT 100
