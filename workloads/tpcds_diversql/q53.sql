WITH ws_agg AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_customer_sk,
        ws.ws_item_sk,
        ws.ws_promo_sk,
        ws.ws_warehouse_sk,
        ws.ws_order_number,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_qty
    FROM web_sales ws
    GROUP BY
        ws.ws_sold_date_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_customer_sk,
        ws.ws_item_sk,
        ws.ws_promo_sk,
        ws.ws_warehouse_sk,
        ws.ws_order_number
)
SELECT
    d_sales.d_date AS sale_date,
    s.s_store_name,
    s.s_state,
    cc.cc_name,
    cp.cp_department,
    c_bill.c_first_name || ' ' || c_bill.c_last_name AS bill_customer_name,
    c_ship.c_first_name || ' ' || c_ship.c_last_name AS ship_customer_name,
    p.p_promo_name,
    w.w_warehouse_name,
    wp.wp_type,
    ws_site.web_name AS website_name,
    reason_sr.r_reason_desc AS store_return_reason,
    reason_wr.r_reason_desc AS web_return_reason,
    ws_agg.total_sales,
    ws_agg.total_qty,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ws_agg.total_sales DESC) AS store_sales_rank
FROM ws_agg
JOIN date_dim d_sales
    ON ws_agg.ws_sold_date_sk = d_sales.d_date_sk
JOIN promotion p
    ON ws_agg.ws_promo_sk = p.p_promo_sk
JOIN warehouse w
    ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
JOIN customer c_bill
    ON ws_agg.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship
    ON ws_agg.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_bill
    ON c_bill.c_current_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_address ca_bill
    ON c_bill.c_current_addr_sk = ca_bill.ca_address_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d_sales.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN reason reason_sr
    ON sr.sr_reason_sk = reason_sr.r_reason_sk
JOIN time_dim td_sr
    ON sr.sr_return_time_sk = td_sr.t_time_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws_agg.ws_order_number
JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN time_dim td_wr
    ON wr.wr_returned_time_sk = td_wr.t_time_sk
JOIN reason reason_wr
    ON wr.wr_reason_sk = reason_wr.r_reason_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sales.d_date_sk
       AND wp.wp_customer_sk = c_bill.c_customer_sk
JOIN web_site ws_site
    ON ws_site.web_open_date_sk = d_sales.d_date_sk
RIGHT JOIN call_center cc
    ON cc.cc_open_date_sk = d_sales.d_date_sk
RIGHT JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_sales.d_date_sk
WHERE
    d_sales.d_year = 2001
    AND s.s_state = 'CA'
    AND reason_sr.r_reason_desc LIKE '%damaged%'
ORDER BY ws_agg.total_sales DESC
LIMIT 100
