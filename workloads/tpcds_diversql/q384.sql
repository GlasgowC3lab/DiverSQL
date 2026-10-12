WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_current_price BETWEEN 5 AND 20
      AND cd.cd_gender = 'F'
      AND cc.cc_state = 'CA'
      AND td.t_hour BETWEEN 9 AND 17
      AND i.i_formulation LIKE '%steel%'
      AND w.w_state = 'CA'
),
filtered_returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_reason_sk
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 0
      AND cr.cr_return_quantity > 0
      AND r.r_reason_desc LIKE '%Damaged%'
),
intersect_orders AS (
    SELECT cs_order_number FROM filtered_sales
    INTERSECT
    SELECT cr_order_number FROM filtered_returns
),
final_set AS (
    SELECT
        fs.cs_order_number,
        fs.cs_net_profit,
        fs.cs_quantity,
        i.i_item_id,
        i.i_product_name,
        c.c_customer_id,
        cd.cd_gender,
        cp.cp_department AS department,
        cc.cc_name,
        sm.sm_type,
        w.w_warehouse_name,
        r.r_reason_desc AS reason_desc,
        wp.wp_url,
        td.t_hour
    FROM filtered_sales fs
    JOIN catalog_returns cr ON fs.cs_order_number = cr.cr_order_number
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN item i ON fs.cs_item_sk = i.i_item_sk
    JOIN customer c ON fs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON fs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_page cp ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON fs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON fs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON fs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON fs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE fs.cs_order_number NOT IN (
            SELECT cr_order_number FROM catalog_returns WHERE cr_reason_sk = 9999
        )
      AND fs.cs_order_number IN (SELECT cs_order_number FROM intersect_orders)
)
SELECT
    cs_order_number,
    cs_net_profit,
    cs_quantity,
    i_item_id,
    c_customer_id,
    department,
    cc_name,
    sm_type,
    w_warehouse_name,
    reason_desc,
    wp_url,
    t_hour,
    RANK() OVER (PARTITION BY department ORDER BY cs_net_profit DESC) AS dept_profit_rank,
    ROW_NUMBER() OVER (ORDER BY cs_net_profit DESC) AS overall_rank
FROM final_set
ORDER BY cs_net_profit DESC
OFFSET 0 LIMIT 100
