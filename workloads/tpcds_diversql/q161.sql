WITH ss_agg AS (
    SELECT
        ss_item_sk,
        ss_sold_date_sk,
        SUM(ss_ext_sales_price) AS total_store_sales,
        SUM(ss_quantity) AS total_store_qty
    FROM store_sales
    GROUP BY ss_item_sk, ss_sold_date_sk
)
SELECT
    cp.cp_catalog_page_number,
    i.i_item_id,
    i.i_brand,
    i.i_category,
    cc.cc_name AS call_center_name,
    sm.sm_type AS ship_mode_type,
    td_cs.t_hour AS sale_hour,
    wsit.web_name AS web_site_name,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
    SUM(ws.ws_ext_sales_price) AS web_sales_amount,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COALESCE(ss_agg.total_store_sales, 0) AS store_sales_amount
FROM catalog_sales cs
RIGHT OUTER JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN time_dim td_cs
    ON cs.cs_sold_time_sk = td_cs.t_time_sk
JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer c_ship
    ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
LEFT JOIN time_dim td_cr
    ON cr.cr_returned_time_sk = td_cr.t_time_sk
LEFT JOIN ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
LEFT JOIN warehouse w_cr
    ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
LEFT JOIN call_center cc_cr
    ON cr.cr_call_center_sk = cc_cr.cc_call_center_sk
LEFT JOIN catalog_page cp_cr
    ON cr.cr_catalog_page_sk = cp_cr.cp_catalog_page_sk
LEFT JOIN item i_cr
    ON cr.cr_item_sk = i_cr.i_item_sk
LEFT JOIN customer c_refunded
    ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
LEFT JOIN customer_demographics cd_refunded
    ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws
    ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN time_dim td_ws
    ON ws.ws_sold_time_sk = td_ws.t_time_sk
JOIN customer c_ws_bill
    ON ws.ws_bill_customer_sk = c_ws_bill.c_customer_sk
JOIN customer_demographics cd_ws_bill
    ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
LEFT JOIN ss_agg
    ON ss_agg.ss_item_sk = i.i_item_sk
    AND ss_agg.ss_sold_date_sk = cs.cs_sold_date_sk
WHERE cs.cs_net_paid_inc_tax > 1000
  AND EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_web_page_sk = wp.wp_web_page_sk
          AND wp2.wp_customer_sk = c_ws_bill.c_customer_sk
    )
GROUP BY
    cp.cp_catalog_page_number,
    i.i_item_id,
    i.i_brand,
    i.i_category,
    cc.cc_name,
    sm.sm_type,
    td_cs.t_hour,
    wsit.web_name,
    COALESCE(ss_agg.total_store_sales, 0)
ORDER BY catalog_sales_amount DESC
LIMIT 100
