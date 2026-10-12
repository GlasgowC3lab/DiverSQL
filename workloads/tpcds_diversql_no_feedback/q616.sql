WITH ws_sample AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    td_ws.t_hour,
    c_bill.c_customer_id,
    site.web_site_id,
    SUM(ws.ws_net_paid) AS total_net_paid,
    COUNT(*) AS cnt_sales,
    LAG(SUM(ws.ws_net_paid)) OVER (PARTITION BY site.web_site_id ORDER BY td_ws.t_hour) AS prev_hour_total,
    ROW_NUMBER() OVER (PARTITION BY site.web_site_id ORDER BY td_ws.t_hour) AS rn
FROM ws_sample ws
-- join to time dimension for the sale timestamp
JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
-- billing customer and related dimensions
JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
-- web page and site dimensions
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
-- web returns linked by order number and item
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                     AND wr.wr_item_sk = ws.ws_item_sk
JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
-- catalog returns (joined through the same return time dimension)
JOIN catalog_returns cr ON cr.cr_returned_time_sk = td_wr.t_time_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
-- store returns (joined via the sales time dimension for illustration)
JOIN store_returns sr ON sr.sr_return_time_sk = td_ws.t_time_sk
JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
-- income band for billing household demographics
JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_refunded_customer_sk = c_bill.c_customer_sk
      AND cr2.cr_returned_time_sk = td_ws.t_time_sk
)
GROUP BY
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    td_ws.t_hour,
    c_bill.c_customer_id,
    site.web_site_id
