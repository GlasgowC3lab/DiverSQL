WITH excluded_orders AS (
   SELECT DISTINCT cr_order_number
   FROM catalog_returns
   EXCEPT
   SELECT DISTINCT wr_order_number
   FROM web_returns
)
SELECT DISTINCT
   c.c_customer_id,
   c.c_first_name,
   c.c_last_name,
   d.d_year,
   cp.cp_department,
   cr.cr_return_amount,
   sr.sr_net_loss,
   wr.wr_net_loss,
   ws.ws_net_profit,
   RANK() OVER (PARTITION BY cp.cp_department ORDER BY cr.cr_net_loss DESC) AS dept_return_loss_rank,
   (
      SELECT COUNT(*)
      FROM web_sales ws2
      WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
   ) AS web_sales_count,
   (
      SELECT DISTINCT p_sub.p_promo_id
      FROM promotion p_sub
      WHERE p_sub.p_promo_sk = ws.ws_promo_sk
   ) AS promo_id,
   (
      SELECT COUNT(*)
      FROM excluded_orders eo
      WHERE eo.cr_order_number = cr.cr_order_number
   ) AS is_excluded_order
FROM
   catalog_returns cr
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
                           AND sr.sr_returned_date_sk = d.d_date_sk
   JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
                         AND wr.wr_returned_date_sk = d.d_date_sk
   JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
                       AND ws.ws_sold_date_sk = d.d_date_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site wes ON ws.ws_web_site_sk = wes.web_site_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE
   d.d_year = 2001
   AND r.r_reason_desc = 'Customer Not Satisfied'
   AND p.p_discount_active = 'Y'
   AND w.w_state = 'CA'
   AND wes.web_country = 'United States'
ORDER BY
   dept_return_loss_rank,
   cr.cr_return_amount DESC
LIMIT 100
