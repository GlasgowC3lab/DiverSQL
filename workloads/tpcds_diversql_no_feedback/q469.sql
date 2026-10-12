WITH base AS (
    SELECT
        d.d_date,
        d.d_year,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        p.p_promo_name,
        p.p_discount_active,
        ss.ss_ticket_number,
        ss.ss_sales_price,
        ss.ss_net_paid,
        ws.ws_net_profit,
        sm.sm_type,
        w.w_warehouse_name,
        wp.wp_url,
        web.web_name,
        cc.cc_name,
        c.c_first_name,
        c.c_last_name,
        r.r_reason_desc,
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        t.t_hour
    FROM tpcds.date_dim d
    LEFT JOIN tpcds.call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN tpcds.store s
        ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN tpcds.item i
        ON i.i_item_sk = inv.inv_item_sk
    LEFT JOIN tpcds.promotion p
        ON p.p_item_sk = i.i_item_sk
    LEFT JOIN tpcds.store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN tpcds.store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN tpcds.reason r
        ON r.r_reason_sk = sr.sr_reason_sk
    LEFT JOIN tpcds.time_dim t
        ON t.t_time_sk = ss.ss_sold_time_sk
    LEFT JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
    LEFT JOIN tpcds.ship_mode sm
        ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    LEFT JOIN tpcds.warehouse w
        ON w.w_warehouse_sk = ws.ws_warehouse_sk
    LEFT JOIN tpcds.web_page wp
        ON wp.wp_web_page_sk = ws.ws_web_page_sk
    LEFT JOIN tpcds.web_site web
        ON web.web_site_sk = ws.ws_web_site_sk
    LEFT JOIN tpcds.customer c
        ON c.c_customer_sk = ws.ws_bill_customer_sk
)
SELECT
    d_date,
    s_store_name,
    i_item_id,
    ss_sales_price,
    ss_net_paid,
    ws_net_profit,
    p_promo_name,
    sm_type,
    w_warehouse_name,
    wp_url,
    web_name,
    cc_name,
    c_first_name,
    c_last_name,
    r_reason_desc,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY ss_net_paid DESC) AS row_num
FROM base
WHERE d_year = 2001
  AND s_state = 'CA'
  AND i_category = 'Books'
  AND ss_ticket_number NOT IN (
        SELECT sr2.sr_ticket_number
        FROM tpcds.store_returns sr2
        WHERE sr2.sr_return_quantity > 0
    )
ORDER BY row_num ASC, d_date DESC
LIMIT 100
