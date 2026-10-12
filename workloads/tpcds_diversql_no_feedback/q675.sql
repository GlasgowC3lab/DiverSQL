WITH key_diff AS (
   SELECT sr.sr_ticket_number AS ticket
   FROM store_returns sr
   EXCEPT
   SELECT cr.cr_order_number AS ticket
   FROM catalog_returns cr
)
SELECT
   d.d_year,
   s.s_store_name,
   p.p_promo_name,
   ws.web_name,
   SUM(sr.sr_return_amt) AS store_return_total,
   SUM(cr.cr_return_amount) AS catalog_return_total,
   SUM(wr.wr_return_amt) AS web_return_total,
   COUNT(DISTINCT sr.sr_ticket_number) AS distinct_store_tickets,
   COUNT(DISTINCT kd.ticket) AS diff_ticket_count
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN customer_demographics cd_cr_refunded ON cr.cr_refunded_cdemo_sk = cd_cr_refunded.cd_demo_sk
JOIN household_demographics hd_cr_refunded ON cr.cr_refunded_hdemo_sk = hd_cr_refunded.hd_demo_sk
JOIN customer_address ca_cr_refunded ON cr.cr_refunded_addr_sk = ca_cr_refunded.ca_address_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN customer_demographics cd_wr_refunded ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
JOIN household_demographics hd_wr_refunded ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
JOIN customer_address ca_wr_refunded ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN key_diff kd ON sr.sr_ticket_number = kd.ticket
WHERE sr.sr_ticket_number NOT IN (
    SELECT wr2.wr_order_number
    FROM web_returns wr2
    WHERE wr2.wr_order_number IS NOT NULL
)
GROUP BY
   d.d_year,
   s.s_store_name,
   p.p_promo_name,
   ws.web_name
ORDER BY store_return_total DESC
LIMIT 100
