WITH
    store_item_keys AS (
        SELECT DISTINCT ss_item_sk FROM store_sales
    ),
    web_item_keys AS (
        SELECT DISTINCT ws_item_sk FROM web_sales
    ),
    store_only_items AS (
        SELECT ss_item_sk FROM store_item_keys
        EXCEPT
        SELECT ws_item_sk FROM web_item_keys
    ),
    store_data AS (
        SELECT
            ss.ss_ticket_number,
            ss.ss_item_sk,
            ss.ss_sold_date_sk,
            ss.ss_net_profit,
            ss.ss_ext_discount_amt,
            i.i_category,
            i.i_item_id,
            c.c_customer_sk,
            ca.ca_state,
            cd.cd_gender,
            hd.hd_income_band_sk,
            p.p_promo_id
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        WHERE ss.ss_item_sk IN (SELECT ss_item_sk FROM store_only_items)
    ),
    store_ret AS (
        SELECT
            sr.sr_ticket_number,
            sr.sr_return_amt,
            sr.sr_net_loss,
            cd.cd_gender AS return_gender
        FROM store_returns sr
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    ),
    web_data AS (
        SELECT
            ws.ws_order_number,
            ws.ws_item_sk,
            ws.ws_sold_date_sk,
            ws.ws_net_profit,
            ws.ws_ext_discount_amt,
            i.i_category,
            i.i_item_id,
            c.c_customer_sk,
            ca.ca_state,
            cd.cd_gender,
            hd.hd_income_band_sk,
            p.p_promo_id,
            sm.sm_type,
            w.w_warehouse_name,
            wp.wp_type AS page_type,
            we.web_site_sk
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    ),
    web_ret AS (
        SELECT
            wr.wr_order_number,
            wr.wr_return_amt,
            wr.wr_net_loss,
            cd.cd_gender AS return_gender
        FROM web_returns wr
        JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    )
SELECT
    sd.ca_state,
    sd.i_category,
    COUNT(DISTINCT sd.c_customer_sk) AS unique_customers,
    SUM(sd.ss_net_profit) AS total_store_profit,
    SUM(wd.ws_net_profit) AS total_web_profit,
    CASE
        WHEN SUM(sd.ss_ext_discount_amt) > (
            SELECT AVG(ss_ext_discount_amt) FROM store_sales
        ) THEN 'HIGH_DISCOUNT'
        ELSE 'LOW_DISCOUNT'
    END AS discount_category,
    SUM(COALESCE(wd.ws_ext_discount_amt, 0)) AS web_discount_sum
FROM store_data sd
LEFT JOIN web_data wd ON sd.ss_item_sk = wd.ws_item_sk
WHERE NOT EXISTS (
    SELECT 1 FROM store_ret sr WHERE sr.sr_ticket_number = sd.ss_ticket_number
)
GROUP BY
    sd.ca_state,
    sd.i_category
ORDER BY total_store_profit DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
