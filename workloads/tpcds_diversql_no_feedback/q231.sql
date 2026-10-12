WITH joined_data AS (
    SELECT
        d_sold.d_year,
        s.s_division_name,
        s.s_state,
        ib.ib_upper_bound,
        cs.cs_net_profit AS catalog_net_profit,
        ss.ss_net_profit AS store_net_profit,
        ws.ws_net_profit AS web_net_profit,
        cr.cr_net_loss AS catalog_net_loss,
        sr.sr_net_loss AS store_net_loss,
        wr.wr_net_loss AS web_net_loss,
        cs.cs_ext_discount_amt,
        ss.ss_ext_discount_amt,
        ws.ws_ext_discount_amt,
        cs.cs_bill_customer_sk,
        ss.ss_customer_sk,
        ws.ws_bill_customer_sk,
        cs.cs_order_number,
        ss.ss_ticket_number,
        ws.ws_order_number
    FROM catalog_sales cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
      ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN household_demographics hd_bill
      ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
      ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN income_band ib
      ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_returned_date_sk = d_sold.d_date_sk
     AND cr.cr_returned_time_sk = t_sold.t_time_sk
     AND cr.cr_item_sk = cs.cs_item_sk
     AND cr.cr_call_center_sk = cc.cc_call_center_sk
     AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN store_sales ss
      ON ss.ss_item_sk = cs.cs_item_sk
     AND ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_returned_date_sk = d_sold.d_date_sk
     AND sr.sr_return_time_sk = t_sold.t_time_sk
     AND sr.sr_item_sk = ss.ss_item_sk
     AND sr.sr_store_sk = s.s_store_sk
     AND sr.sr_hdemo_sk = hd_bill.hd_demo_sk
    JOIN web_sales ws
      ON ws.ws_item_sk = cs.cs_item_sk
     AND ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_returned_date_sk = d_sold.d_date_sk
     AND wr.wr_returned_time_sk = t_sold.t_time_sk
     AND wr.wr_item_sk = ws.ws_item_sk
     AND wr.wr_web_page_sk = wp.wp_web_page_sk
     AND wr.wr_refunded_hdemo_sk = hd_bill.hd_demo_sk
    WHERE d_sold.d_year = 2001
      AND ib.ib_upper_bound >= 50000
      AND s.s_state = 'CA'
)
SELECT
    d_year,
    s_division_name,
    COUNT(DISTINCT cs_bill_customer_sk) AS unique_bill_customers,
    COUNT(DISTINCT ss_customer_sk) AS unique_store_customers,
    COUNT(DISTINCT ws_bill_customer_sk) AS unique_web_customers,
    SUM(COALESCE(catalog_net_profit, 0)) AS total_catalog_profit,
    SUM(COALESCE(store_net_profit, 0)) AS total_store_profit,
    SUM(COALESCE(web_net_profit, 0)) AS total_web_profit,
    SUM(COALESCE(catalog_net_loss, 0) + COALESCE(store_net_loss, 0) + COALESCE(web_net_loss, 0)) AS total_return_loss,
    AVG(cs_ext_discount_amt) AS avg_catalog_discount,
    AVG(ss_ext_discount_amt) AS avg_store_discount,
    AVG(ws_ext_discount_amt) AS avg_web_discount
FROM joined_data
GROUP BY d_year, s_division_name
ORDER BY d_year DESC, total_store_profit DESC
LIMIT 100
