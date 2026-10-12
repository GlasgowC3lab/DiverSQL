WITH orders_without_return AS (
        SELECT ws_order_number
        FROM web_sales
        EXCEPT
        SELECT wr_order_number
        FROM web_returns
    ),
    high_value_orders AS (
        SELECT ws_order_number
        FROM web_sales
        WHERE ws_ext_sales_price > 5000
    )
SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    cd.cd_gender,
    ss.ss_net_paid,
    ws.ws_ext_sales_price,
    we.web_name,
    CASE
        WHEN s.s_city = 'Springfield' THEN 'Urban'
        ELSE 'Rural'
    END AS city_type,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_net_paid DESC) AS sales_rank,
    COUNT(cr.cr_order_number) OVER (PARTITION BY s.s_store_id) AS total_returns,
    (SELECT COUNT(*) FROM high_value_orders) AS high_value_order_cnt
FROM
    store_sales ss
RIGHT OUTER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
LEFT JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
LEFT JOIN warehouse w_cr
    ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
LEFT JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN web_sales ws
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
LEFT JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
LEFT JOIN warehouse w_ws
    ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
WHERE
    s.s_state IN ('CA', 'TX', 'NY')
    AND cc.cc_market_manager = 'John Doe'
    AND ws.ws_ext_sales_price > 1000
    AND cr.cr_return_amount < 500
    AND we.web_company_id = 1
    AND cd.cd_gender = 'M'
    AND ss.ss_ticket_number NOT IN (SELECT ws_order_number FROM high_value_orders)
    AND ss.ss_ticket_number IN (SELECT ws_order_number FROM orders_without_return)
ORDER BY
    sales_rank,
    s.s_store_id
LIMIT 100
