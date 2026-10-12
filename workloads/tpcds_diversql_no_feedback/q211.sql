WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_returning_customer_sk,
        cr.cr_returning_cdemo_sk,
        cr.cr_returning_hdemo_sk,
        cr.cr_returning_addr_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_ship_mode_sk,
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cr.cr_order_number,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_refunded_cash,
        cr.cr_reversed_charge,
        cr.cr_store_credit,
        cr.cr_net_loss,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_customer_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_ship_addr_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk AS cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_wholesale_cost,
        cs.cs_list_price,
        cs.cs_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_ext_sales_price,
        cs.cs_ext_wholesale_cost,
        cs.cs_ext_list_price,
        cs.cs_ext_tax,
        cs.cs_coupon_amt,
        cs.cs_ext_ship_cost,
        cs.cs_net_paid,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_paid_inc_ship,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_net_profit
    FROM catalog_returns cr
    FULL OUTER JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
)
SELECT
    cp.cp_department,
    cp.cp_catalog_number,
    sm.sm_type,
    r.r_reason_desc,
    td.t_hour,
    COUNT(DISTINCT base.cs_order_number) AS num_sales_orders,
    SUM(base.cs_net_paid) AS total_sales_net_paid,
    SUM(base.cr_return_amount) AS total_return_amount,
    AVG(base.cs_quantity) AS avg_quantity_sold,
    MIN(base.cs_wholesale_cost) AS min_wholesale_cost,
    MAX(ss.ss_wholesale_cost) AS max_store_wholesale_cost,
    SUM(wr.wr_return_amt) AS total_web_return_amount
FROM base
LEFT JOIN catalog_page cp
    ON base.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm
    ON base.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN reason r
    ON base.cr_reason_sk = r.r_reason_sk
LEFT JOIN time_dim td
    ON base.cs_sold_time_sk = td.t_time_sk
LEFT JOIN store_sales ss
    ON ss.ss_sold_time_sk = td.t_time_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_time_sk = td.t_time_sk
LEFT JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
    cp.cp_catalog_number = 15
    AND cp.cp_catalog_page_number = 13
    AND sm.sm_type = 'AIR'
    AND r.r_reason_desc = 'Customer Not Satisfied'
    AND td.t_hour BETWEEN 9 AND 17
    AND ss.ss_wholesale_cost > 40
    AND wr.wr_return_amt > 500
GROUP BY
    cp.cp_department,
    cp.cp_catalog_number,
    sm.sm_type,
    r.r_reason_desc,
    td.t_hour
HAVING
    SUM(base.cs_net_paid) > 10000
ORDER BY
    total_sales_net_paid DESC
LIMIT 100
