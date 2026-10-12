WITH
    -- Scalar subquery used later for comparison
    scalar_avg AS (
        SELECT AVG(cs2.cs_ext_sales_price) AS avg_price
        FROM catalog_sales cs2
        WHERE cs2.cs_sold_date_sk = 2450815
    )
SELECT
    t.t_hour,
    hd1.hd_buy_potential,
    ca1.ca_state,
    ib.ib_upper_bound,
    sm.sm_type,
    cc.cc_name,
    cp.cp_department,
    COUNT(DISTINCT ss.ss_ticket_number)                         AS store_sales_orders,
    SUM(ss.ss_net_paid)                                         AS total_store_sales,
    SUM(sr.sr_net_loss)                                         AS total_store_returns_loss,
    SUM(cs.cs_ext_sales_price)                                  AS total_catalog_sales,
    SUM(cr.cr_net_loss)                                         AS total_catalog_returns_loss,
    SUM(wr.wr_net_loss)                                         AS total_web_returns_loss,
    AVG(cs.cs_sales_price)                                      AS avg_catalog_item_price,
    MIN(ss.ss_sales_price)                                      AS min_store_item_price,
    MAX(wr.wr_return_amt)                                      AS max_web_return_amount
FROM store_sales ss
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN household_demographics hd1 ON ss.ss_hdemo_sk = hd1.hd_demo_sk
JOIN income_band ib ON hd1.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca1 ON ss.ss_addr_sk = ca1.ca_address_sk

-- Store returns and its related dimensions
JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
                     AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN household_demographics hd2 ON sr.sr_hdemo_sk = hd2.hd_demo_sk
JOIN customer_address ca2 ON sr.sr_addr_sk = ca2.ca_address_sk
JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk

-- Catalog sales and its related dimensions
JOIN catalog_sales cs ON cs.cs_item_sk = ss.ss_item_sk
                     AND cs.cs_order_number = ss.ss_ticket_number
JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN household_demographics hd3 ON cs.cs_bill_hdemo_sk = hd3.hd_demo_sk
JOIN customer_address ca3 ON cs.cs_bill_addr_sk = ca3.ca_address_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk

-- Catalog returns and its related dimensions
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                       AND cr.cr_item_sk = cs.cs_item_sk
JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN call_center cc_cr ON cr.cr_call_center_sk = cc_cr.cc_call_center_sk
JOIN catalog_page cp_cr ON cr.cr_catalog_page_sk = cp_cr.cp_catalog_page_sk
JOIN household_demographics hd4 ON cr.cr_refunded_hdemo_sk = hd4.hd_demo_sk
JOIN customer_address ca4 ON cr.cr_refunded_addr_sk = ca4.ca_address_sk

-- Web returns and its related dimensions (joined through the same time dimension as store sales)
JOIN web_returns wr ON wr.wr_item_sk = ss.ss_item_sk
JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk

WHERE
    ca1.ca_state = 'CA'
    AND ib.ib_upper_bound >= 50000
    AND sm.sm_type = 'NEXT DAY'
    AND cc.cc_name = 'Call Center 1'
    AND cp.cp_department = 'Electronics'
    AND t.t_hour BETWEEN 9 AND 17
    AND r_sr.r_reason_desc = 'Did not get it on time'
    AND cs.cs_ext_sales_price > (SELECT avg_price FROM scalar_avg)

GROUP BY
    t.t_hour,
    hd1.hd_buy_potential,
    ca1.ca_state,
    ib.ib_upper_bound,
    sm.sm_type,
    cc.cc_name,
    cp.cp_department

ORDER BY total_store_sales DESC
LIMIT 100
