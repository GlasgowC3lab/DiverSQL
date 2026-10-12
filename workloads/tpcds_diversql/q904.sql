WITH
    store_sales_agg AS (
        SELECT
            ss_item_sk,
            ss_store_sk,
            ss_sold_date_sk,
            SUM(ss_ext_sales_price) AS total_ext_sales,
            SUM(ss_net_profit) AS total_net_profit,
            SUM(ss_quantity) AS total_qty
        FROM store_sales
        GROUP BY ss_item_sk, ss_store_sk, ss_sold_date_sk
    ),
    inventory_agg AS (
        SELECT
            inv_item_sk,
            inv_warehouse_sk,
            SUM(inv_quantity_on_hand) AS total_qty_on_hand
        FROM inventory
        WHERE inv_warehouse_sk IN (
            SELECT w_warehouse_sk FROM warehouse WHERE w_city = 'Seattle'
        )
        GROUP BY inv_item_sk, inv_warehouse_sk
    ),
    returned_not_sold AS (
        SELECT cr_item_sk FROM catalog_returns
        EXCEPT
        SELECT ss_item_sk FROM store_sales
    ),
    online_sold_and_returned AS (
        SELECT ws_item_sk FROM web_sales
        INTERSECT
        SELECT wr_item_sk FROM web_returns
    )
SELECT
    i1.i_item_id,
    i1.i_product_name,
    s.s_store_name,
    w.w_warehouse_name,
    t_ret.t_hour,
    SUM(ssag.total_ext_sales)               AS store_total_sales,
    SUM(ssag.total_qty)                     AS store_total_qty,
    SUM(ssag.total_net_profit)              AS store_total_profit,
    CASE WHEN SUM(ssag.total_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    SUM(cr.cr_return_amount)                AS catalog_return_amount,
    SUM(ws.ws_net_paid)                     AS web_net_paid,
    COUNT(DISTINCT cr.cr_order_number)      AS catalog_return_cnt,
    (SELECT COUNT(*) FROM returned_not_sold)               AS cnt_returned_not_sold,
    (SELECT COUNT(*) FROM online_sold_and_returned)        AS cnt_online_sold_and_returned,
    lp.max_price
FROM catalog_returns cr
JOIN item i1
    ON cr.cr_item_sk = i1.i_item_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t_ret
    ON cr.cr_returned_time_sk = t_ret.t_time_sk
JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN store_sales_agg ssag
    ON ssag.ss_item_sk = i1.i_item_sk
JOIN store s
    ON ssag.ss_store_sk = s.s_store_sk
JOIN inventory_agg invag
    ON invag.inv_item_sk = i1.i_item_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i1.i_item_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws
    ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN time_dim t_ws
    ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN customer_demographics cd_ws
    ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
JOIN customer_address ca_ws
    ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN time_dim t_wr
    ON wr.wr_returned_time_sk = t_wr.t_time_sk
CROSS JOIN LATERAL (
    SELECT MAX(i2.i_current_price) AS max_price
    FROM item i2
    WHERE i2.i_item_sk = i1.i_item_sk
) lp
WHERE cr.cr_reason_sk IN (
    SELECT r2.r_reason_sk
    FROM reason r2
    WHERE r2.r_reason_desc LIKE '%not work%'
)
GROUP BY
    i1.i_item_id,
    i1.i_product_name,
    s.s_store_name,
    w.w_warehouse_name,
    t_ret.t_hour,
    lp.max_price
ORDER BY store_total_sales DESC
LIMIT 100
