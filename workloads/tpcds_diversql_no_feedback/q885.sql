WITH sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        wsite.web_name,
        t_sold.t_hour,
        p.p_promo_name,
        wh.w_warehouse_name,
        ca_bill.ca_city        AS bill_city,
        ca_ship.ca_city        AS ship_city,
        inv.inv_quantity_on_hand,
        cr.cr_return_amount,
        r_cr.r_reason_desc    AS catalog_return_reason,
        cp.cp_description,
        cc.cc_name,
        wr.wr_return_amt,
        r_wr.r_reason_desc    AS web_return_reason,
        sr.sr_net_loss,
        r_sr.r_reason_desc    AS store_return_reason,
        s.s_store_name,
        ca_sr.ca_city          AS store_return_city,
        t_return.t_hour        AS web_return_hour,
        t_cr.t_hour            AS catalog_return_hour,
        t_sr.t_hour            AS store_return_hour
    FROM web_sales ws
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN warehouse wh
        ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t_sold
        ON ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN inventory inv
        ON wh.w_warehouse_sk = inv.inv_warehouse_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN time_dim t_return
        ON wr.wr_returned_time_sk = t_return.t_time_sk
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN catalog_returns cr
        ON ws.ws_order_number = cr.cr_order_number
    LEFT JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    LEFT JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN store_returns sr
        ON TRUE                                 -- cross‑join to make the table part of the query
    LEFT JOIN time_dim t_sr
        ON sr.sr_return_time_sk = t_sr.t_time_sk
    LEFT JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN customer_address ca_sr
        ON sr.sr_addr_sk = ca_sr.ca_address_sk
)
SELECT
    web_name,
    t_hour,
    SUM(total_sales)   AS sum_sales,
    SUM(total_profit)  AS sum_profit,
    SUM(total_returns) AS sum_returns,
    SUM(total_inventory) AS sum_inventory,
    COUNT(*)           AS row_cnt
FROM (
    SELECT
        web_name,
        t_hour,
        ws_ext_sales_price AS total_sales,
        ws_net_profit      AS total_profit,
        COALESCE(wr_return_amt, 0)       AS total_returns,
        COALESCE(inv_quantity_on_hand, 0) AS total_inventory
    FROM sales_data
    CROSS JOIN (SELECT ARRAY['A','B','C'] AS grp) g
    CROSS JOIN UNNEST(g.grp) AS t(label)
) sub
GROUP BY ROLLUP (web_name, t_hour)
ORDER BY web_name ASC NULLS LAST,
         t_hour   ASC NULLS LAST
LIMIT 100
