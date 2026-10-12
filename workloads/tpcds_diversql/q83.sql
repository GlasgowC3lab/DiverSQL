WITH
    cust_demo AS (
        SELECT
            c.c_customer_sk,
            c.c_customer_id,
            c.c_last_name,
            c.c_birth_month,
            c.c_birth_year,
            cd.cd_gender,
            hd.hd_buy_potential,
            hd.hd_income_band_sk,
            ib.ib_lower_bound,
            ib.ib_upper_bound
        FROM customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE c.c_birth_month = 5
          AND c.c_birth_year = 1975
          AND ib.ib_lower_bound >= 50000
    ),
    store_metrics AS (
        SELECT
            ss.ss_ticket_number,
            ss.ss_customer_sk,
            ss.ss_sold_date_sk,
            ss.ss_sold_time_sk,
            ss.ss_quantity,
            ss.ss_net_paid,
            ss.ss_net_profit,
            s.s_store_sk,
            s.s_state,
            p.p_promo_sk,
            p.p_discount_active,
            t.t_hour
        FROM store_sales ss
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        WHERE s.s_state = 'CA'
          AND p.p_discount_active = 'Y'
          AND t.t_hour BETWEEN 9 AND 17
    ),
    store_ret AS (
        SELECT
            sr.sr_ticket_number,
            sr.sr_customer_sk,
            sr.sr_return_quantity,
            sr.sr_return_amt,
            sr.sr_net_loss,
            t.t_hour
        FROM store_returns sr
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        WHERE t.t_hour BETWEEN 9 AND 17
    ),
    web_metrics AS (
        SELECT
            ws.ws_order_number,
            ws.ws_bill_customer_sk,
            ws.ws_sold_date_sk,
            ws.ws_sold_time_sk,
            ws.ws_quantity,
            ws.ws_net_paid,
            ws.ws_net_profit,
            wp.wp_web_page_sk,
            w.w_warehouse_sk,
            p.p_promo_sk,
            t.t_hour
        FROM web_sales ws
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        WHERE w.w_state = 'CA'
          AND t.t_hour BETWEEN 9 AND 17
    ),
    web_ret AS (
        SELECT
            wr.wr_order_number,
            wr.wr_refunded_customer_sk,
            wr.wr_return_amt,
            wr.wr_net_loss,
            t.t_hour
        FROM web_returns wr
        JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
        WHERE t.t_hour BETWEEN 9 AND 17
    ),
    catalog_ret AS (
        SELECT
            cr.cr_order_number,
            cr.cr_refunded_customer_sk,
            cr.cr_return_amount,
            cr.cr_net_loss,
            cp.cp_department,
            w.w_warehouse_sk,
            t.t_hour
        FROM catalog_returns cr
        JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        WHERE cp.cp_department = 'Electronics'
          AND t.t_hour BETWEEN 9 AND 17
    ),
    inventory_cte AS (
        SELECT
            inv.inv_item_sk,
            inv.inv_quantity_on_hand,
            w.w_warehouse_sk,
            w.w_state
        FROM inventory inv
        JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
        WHERE inv.inv_quantity_on_hand > 100
          AND w.w_state = 'CA'
    ),
    intersect_customers AS (
        SELECT c.c_customer_sk
        FROM store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        INTERSECT
        SELECT c.c_customer_sk
        FROM web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    ),
    full_outer_sr AS (
        SELECT
            ss.ss_ticket_number,
            ss.ss_net_paid,
            sr.sr_return_amt,
            sr.sr_net_loss
        FROM store_sales ss
        FULL OUTER JOIN store_returns sr
            ON ss.ss_ticket_number = sr.sr_ticket_number
    )
SELECT
    cd.c_customer_id,
    cd.c_last_name,
    cd.cd_gender,
    cd.hd_buy_potential,
    SUM(sm.ss_net_paid) AS total_store_sales,
    SUM(wm.ws_net_paid) AS total_web_sales,
    SUM(cr.cr_return_amount) AS total_catalog_returns,
    SUM(sr.sr_return_amt) AS total_store_returns,
    SUM(wr.wr_return_amt) AS total_web_returns,
    SUM(ic.inv_quantity_on_hand) AS total_inventory,
    COUNT(DISTINCT sm.ss_ticket_number) AS store_orders,
    COUNT(DISTINCT wm.ws_order_number) AS web_orders,
    COUNT(DISTINCT fos.ss_ticket_number) AS full_outer_ticket_count
FROM cust_demo cd
LEFT JOIN store_metrics sm ON cd.c_customer_sk = sm.ss_customer_sk
LEFT JOIN store_ret sr ON sm.ss_ticket_number = sr.sr_ticket_number
LEFT JOIN web_metrics wm ON cd.c_customer_sk = wm.ws_bill_customer_sk
LEFT JOIN web_ret wr ON wm.ws_order_number = wr.wr_order_number
LEFT JOIN catalog_ret cr ON cd.c_customer_sk = cr.cr_refunded_customer_sk
LEFT JOIN inventory_cte ic ON wm.w_warehouse_sk = ic.w_warehouse_sk
LEFT JOIN full_outer_sr fos ON sm.ss_ticket_number = fos.ss_ticket_number
WHERE cd.c_customer_sk IN (SELECT c_customer_sk FROM intersect_customers)
GROUP BY
    cd.c_customer_id,
    cd.c_last_name,
    cd.cd_gender,
    cd.hd_buy_potential
ORDER BY total_store_sales DESC
LIMIT 100
