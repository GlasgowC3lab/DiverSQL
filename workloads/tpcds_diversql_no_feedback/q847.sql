/* Goal: Compute sales and return metrics by ship mode and promotion, including subtotals and a grand total, while excluding orders that have a matching catalog return (anti‑join). The query joins all fourteen selected TPC‑DS tables, re‑uses the CUSTOMER table twice under different aliases, and uses a GROUP BY ROLLUP with a global ROW_NUMBER. */
WITH base AS (
    SELECT
        sm.sm_type                         AS ship_mode_type,
        p.p_promo_name                     AS promo_name,
        ss.ss_ext_sales_price              AS store_sales_amount,
        ws.ws_ext_sales_price              AS web_sales_amount,
        cr.cr_return_amt_inc_tax           AS catalog_return_amount,
        inv.inv_quantity_on_hand           AS inventory_qty,
        ca.ca_state                        AS customer_state,
        hd.hd_income_band_sk               AS income_band,
        c_store.c_preferred_cust_flag      AS preferred_flag,
        c_ws_bill.c_first_name             AS bill_first_name,
        c_ws_ship.c_first_name             AS ship_first_name,
        td.t_hour                          AS hour_of_day,
        w.w_warehouse_name                 AS warehouse_name,
        wp.wp_type                         AS web_page_type,
        ws.ws_order_number                 AS order_number,
        ss.ss_ticket_number                AS ticket_number
    FROM store_sales ss
    JOIN time_dim td                     ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c_store                ON ss.ss_customer_sk = c_store.c_customer_sk
    JOIN household_demographics hd       ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca            ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p                     ON ss.ss_promo_sk = p.p_promo_sk
    /* Connect to web_sales through the common promotion key */
    JOIN web_sales ws                    ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm                    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w                     ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp                     ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit                    ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN customer c_ws_bill              ON ws.ws_bill_customer_sk = c_ws_bill.c_customer_sk
    JOIN customer c_ws_ship              ON ws.ws_ship_customer_sk = c_ws_ship.c_customer_sk
    LEFT JOIN catalog_returns cr        ON cr.cr_returned_time_sk = td.t_time_sk
                                         AND cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv             ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr            ON wr.wr_item_sk = ws.ws_item_sk
                                         AND wr.wr_order_number = ws.ws_order_number
                                         AND wr.wr_returned_time_sk = td.t_time_sk
    WHERE NOT EXISTS (
        SELECT 1 FROM catalog_returns cr2
        WHERE cr2.cr_order_number = ss.ss_ticket_number
    )
)
SELECT
    ship_mode_type,
    promo_name,
    SUM(store_sales_amount)   AS total_store_sales,
    SUM(web_sales_amount)     AS total_web_sales,
    SUM(catalog_return_amount) AS total_catalog_return,
    SUM(inventory_qty)        AS total_inventory_qty,
    ROW_NUMBER() OVER (ORDER BY ship_mode_type, promo_name) AS rn
FROM base
GROUP BY ROLLUP (ship_mode_type, promo_name)
ORDER BY ship_mode_type, promo_name
LIMIT 100
