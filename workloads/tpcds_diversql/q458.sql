WITH
    dim_item AS (
        SELECT i_item_sk, i_item_id, i_rec_start_date, i_current_price
        FROM item
        WHERE i_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2002-12-31'
    ),
    dim_time AS (
        SELECT t_time_sk, t_hour, t_shift
        FROM time_dim
    ),
    dim_hd AS (
        SELECT hd_demo_sk, hd_buy_potential
        FROM household_demographics
    ),
    dim_reason AS (
        SELECT r_reason_sk, r_reason_desc
        FROM reason
    ),
    dim_ship AS (
        SELECT sm_ship_mode_sk, sm_code, sm_contract
        FROM ship_mode
        WHERE sm_code = 'AIR'
    ),
    dim_call AS (
        SELECT cc_call_center_sk, cc_country
        FROM call_center
        WHERE cc_country = 'United States'
    ),
    dim_web_page AS (
        SELECT wp_web_page_sk, wp_url
        FROM web_page
        WHERE wp_rec_start_date > DATE '2000-01-01'
    ),
    store_order AS (
        SELECT sr_ticket_number AS order_num FROM store_returns
    ),
    catalog_order AS (
        SELECT cr_order_number AS order_num FROM catalog_returns
    ),
    orders_excluding_store AS (
        SELECT order_num FROM catalog_order
        EXCEPT
        SELECT order_num FROM store_order
    )
SELECT
    ws.ws_sold_date_sk,
    i.i_item_id,
    sm.sm_code,
    wp.wp_url,
    COUNT(DISTINCT ws.ws_order_number)               AS distinct_orders,
    SUM(ws.ws_net_paid)                              AS total_net_paid,
    AVG(ws.ws_ext_tax)                               AS avg_ext_tax,
    COUNT(DISTINCT r.r_reason_desc)                 AS distinct_reasons,
    COUNT(DISTINCT hd.hd_buy_potential)             AS distinct_buy_potential
FROM web_sales ws
JOIN dim_item i            ON ws.ws_item_sk = i.i_item_sk
JOIN dim_time t            ON ws.ws_sold_time_sk = t.t_time_sk
JOIN dim_hd hd             ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN dim_ship sm           ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN dim_web_page wp       ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN store_returns sr      ON sr.sr_item_sk = i.i_item_sk
                             AND sr.sr_return_time_sk = t.t_time_sk
                             AND sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN dim_reason r          ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_returns cr    ON cr.cr_item_sk = i.i_item_sk
                             AND cr.cr_returned_time_sk = t.t_time_sk
                             AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN dim_call cc           ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN dim_reason r2         ON cr.cr_reason_sk = r2.r_reason_sk
WHERE ws.ws_ext_tax > 50.00
  AND i.i_current_price < 100.00
  AND wp.wp_url LIKE 'http%'
  AND ws.ws_order_number IN (SELECT order_num FROM orders_excluding_store)
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = ws.ws_item_sk
          AND cr2.cr_return_quantity > 0
    )
GROUP BY
    ws.ws_sold_date_sk,
    i.i_item_id,
    sm.sm_code,
    wp.wp_url
ORDER BY total_net_paid DESC
