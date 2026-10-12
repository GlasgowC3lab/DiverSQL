WITH agg AS (
    SELECT
        cc.cc_state,
        sm.sm_type,
        wh.w_state,
        p.p_discount_active,
        r.r_reason_desc,
        SUM(cs.cs_net_paid) AS total_sales,
        AVG(ws.ws_net_paid) AS avg_web_sales,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        MIN(cr.cr_return_amount) AS min_return_amount,
        MAX(ws.ws_net_profit) AS max_web_profit
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse wh
        ON cs.cs_warehouse_sk = wh.w_warehouse_sk
    JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN tpcds.reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN tpcds.inventory inv
        ON inv.inv_warehouse_sk = wh.w_warehouse_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    WHERE cc.cc_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND r.r_reason_desc LIKE '%damaged%'
      AND wh.w_state = 'TX'
      AND wp.wp_type = 'product'
    GROUP BY
        cc.cc_state,
        sm.sm_type,
        wh.w_state,
        p.p_discount_active,
        r.r_reason_desc
)
SELECT
    *,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100
