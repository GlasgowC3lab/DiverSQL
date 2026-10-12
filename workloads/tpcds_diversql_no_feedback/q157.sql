WITH
    -- Alias date_dim for the various date roles
    d_sold AS (SELECT * FROM date_dim),
    d_ship AS (SELECT * FROM date_dim),
    d_return AS (SELECT * FROM date_dim),
    d_cr_returned AS (SELECT * FROM date_dim),
    d_cc_open AS (SELECT * FROM date_dim),
    d_cc_closed AS (SELECT * FROM date_dim),
    d_cp_start AS (SELECT * FROM date_dim),
    d_cp_end AS (SELECT * FROM date_dim),
    d_ws_ship AS (SELECT * FROM date_dim),
    d_ws_promo_start AS (SELECT * FROM date_dim),
    d_ws_promo_end AS (SELECT * FROM date_dim),
    d_web_site_open AS (SELECT * FROM date_dim),
    d_web_site_close AS (SELECT * FROM date_dim),
    d_wp_creation AS (SELECT * FROM date_dim),
    d_wp_access AS (SELECT * FROM date_dim)
SELECT
    d_sold.d_year,
    sm.sm_type,
    p.p_promo_name,
    ws.ws_web_site_sk,
    ws.ws_order_number,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_sales_price) AS total_sales_price,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    ROW_NUMBER() OVER (PARTITION BY d_sold.d_year ORDER BY SUM(ws.ws_net_paid) DESC) AS profit_rank
FROM web_sales ws
JOIN d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold ON ws.ws_sold_time_sk = t_sold.t_time_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk

-- web_returns linkage
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
               AND wr.wr_item_sk = ws.ws_item_sk
JOIN d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return ON wr.wr_returned_time_sk = t_return.t_time_sk
JOIN household_demographics hd_refund ON wr.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
JOIN household_demographics hd_returning ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN web_page wp_ret ON wr.wr_web_page_sk = wp_ret.wp_web_page_sk

-- catalog_returns linkage
JOIN catalog_returns cr ON cr.cr_order_number = ws.ws_order_number
JOIN d_cr_returned ON cr.cr_returned_date_sk = d_cr_returned.d_date_sk
JOIN time_dim t_cr_returned ON cr.cr_returned_time_sk = t_cr_returned.t_time_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN household_demographics hd_cr_refund ON cr.cr_refunded_hdemo_sk = hd_cr_refund.hd_demo_sk
JOIN household_demographics hd_cr_returning ON cr.cr_returning_hdemo_sk = hd_cr_returning.hd_demo_sk

WHERE d_sold.d_year = 2001
  AND sm.sm_type = 'OVERNIGHT'
  AND wp.wp_autogen_flag = 'Y'
  AND p.p_discount_active = 'Y'
  AND EXISTS (
        SELECT 1 FROM catalog_returns cr2
        WHERE cr2.cr_order_number = ws.ws_order_number
          AND cr2.cr_return_amount > 100
      )
GROUP BY d_sold.d_year, sm.sm_type, p.p_promo_name, ws.ws_web_site_sk, ws.ws_order_number
ORDER BY total_net_paid DESC
LIMIT 100
