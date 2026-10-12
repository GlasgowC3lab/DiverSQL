WITH filtered_items AS (
    SELECT i_item_sk, i_brand_id, i_category, i_current_price
    FROM item
    WHERE i_item_sk IN (
        SELECT p_item_sk
        FROM promotion
        WHERE p_cost > 5000
    )
)
SELECT
    d_sale.d_year,
    cp.cp_department,
    sm_ws.sm_carrier,
    p.p_promo_name,
    s.s_store_name,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt
FROM web_sales ws
JOIN filtered_items i
    ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d_sale
    ON ws.ws_sold_date_sk = d_sale.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN time_dim t_sold
    ON ws.ws_sold_time_sk = t_sold.t_time_sk
JOIN customer cust_bill
    ON ws.ws_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer cust_ship
    ON ws.ws_ship_customer_sk = cust_ship.c_customer_sk
JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws
    ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_returned_date_sk = d_sale.d_date_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN warehouse w_cr
    ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
JOIN date_dim d_wr_return
    ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
JOIN time_dim t_wr_return
    ON wr.wr_returned_time_sk = t_wr_return.t_time_sk
JOIN customer cust_refund_wr
    ON wr.wr_refunded_customer_sk = cust_refund_wr.c_customer_sk
JOIN store s
    ON s.s_closed_date_sk = d_sale.d_date_sk
WHERE p.p_discount_active = 'Y'
GROUP BY
    d_sale.d_year,
    cp.cp_department,
    sm_ws.sm_carrier,
    p.p_promo_name,
    s.s_store_name
ORDER BY total_sales DESC
LIMIT 100
