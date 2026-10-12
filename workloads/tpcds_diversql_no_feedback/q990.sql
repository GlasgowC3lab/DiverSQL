WITH base AS (
    SELECT
        cc.cc_name AS call_center_name,
        sm.sm_type AS ship_type,
        t_sold.t_hour AS sale_hour,
        cd_bill.cd_gender AS customer_gender,
        COUNT(DISTINCT cs.cs_order_number) AS orders,
        SUM(cs.cs_net_profit) AS total_profit,
        COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
        COALESCE(SUM(sr.sr_return_amt), 0) AS total_store_return,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_profit
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    -- Re‑use the Customer dimension under a different alias (store customer)
    JOIN customer c_store
        ON c_store.c_customer_sk = c_bill.c_customer_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN time_dim t_return
        ON cr.cr_returned_time_sk = t_return.t_time_sk
    LEFT JOIN customer c_refund
        ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
    LEFT JOIN customer_demographics cd_refund
        ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    LEFT JOIN customer_address ca_refund
        ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_customer_sk = c_store.c_customer_sk
    LEFT JOIN time_dim t_sr
        ON sr.sr_return_time_sk = t_sr.t_time_sk
    LEFT JOIN customer_demographics cd_store
        ON sr.sr_cdemo_sk = cd_store.cd_demo_sk
    LEFT JOIN customer_address ca_store
        ON sr.sr_addr_sk = ca_store.ca_address_sk
    -- Web sales joined via the same sold time dimension
    LEFT JOIN web_sales ws
        ON ws.ws_sold_time_sk = t_sold.t_time_sk
    LEFT JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    GROUP BY
        cc.cc_name,
        sm.sm_type,
        t_sold.t_hour,
        cd_bill.cd_gender
    HAVING
        SUM(cs.cs_net_profit) > 10000
)
SELECT
    b.*, 
    lbl.label
FROM base b
CROSS JOIN (SELECT 'A' AS label UNION ALL SELECT 'B' AS label) AS lbl
ORDER BY b.total_profit DESC
LIMIT 100
