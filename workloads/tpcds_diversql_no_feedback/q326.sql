WITH joined_data AS (
    SELECT
        store.s_store_id            AS store_id,
        promotion.p_promo_id        AS p_promo_id,
        catalog_page.cp_catalog_page_id AS cp_catalog_page_id,
        web_page.wp_web_page_id    AS wp_web_page_id,
        ship_mode.sm_ship_mode_id  AS sm_ship_mode_id,
        store_sales.ss_net_profit  AS ss_net_profit,
        store_sales.ss_quantity    AS ss_quantity,
        web_sales.ws_net_paid_inc_ship AS ws_net_paid_inc_ship,
        catalog_returns.cr_return_amount AS cr_return_amount
    FROM tpcds.store_sales
    JOIN tpcds.customer
        ON store_sales.ss_customer_sk = customer.c_customer_sk
    JOIN tpcds.household_demographics
        ON store_sales.ss_hdemo_sk = household_demographics.hd_demo_sk
    JOIN tpcds.income_band
        ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
    JOIN tpcds.customer_address
        ON store_sales.ss_addr_sk = customer_address.ca_address_sk
    JOIN tpcds.store
        ON store_sales.ss_store_sk = store.s_store_sk
    JOIN tpcds.promotion
        ON store_sales.ss_promo_sk = promotion.p_promo_sk
    JOIN tpcds.store_returns
        ON store_returns.sr_ticket_number = store_sales.ss_ticket_number
    JOIN tpcds.catalog_returns
        ON catalog_returns.cr_refunded_customer_sk = customer.c_customer_sk
    JOIN tpcds.catalog_page
        ON catalog_returns.cr_catalog_page_sk = catalog_page.cp_catalog_page_sk
    JOIN tpcds.ship_mode
        ON catalog_returns.cr_ship_mode_sk = ship_mode.sm_ship_mode_sk
    JOIN tpcds.warehouse
        ON catalog_returns.cr_warehouse_sk = warehouse.w_warehouse_sk
    JOIN tpcds.inventory
        ON inventory.inv_warehouse_sk = warehouse.w_warehouse_sk
    JOIN tpcds.web_sales
        ON web_sales.ws_bill_customer_sk = customer.c_customer_sk
    JOIN tpcds.web_page
        ON web_sales.ws_web_page_sk = web_page.wp_web_page_sk
    WHERE store.s_state = 'CA'
      AND promotion.p_discount_active = 'Y'
      AND catalog_page.cp_end_date_sk BETWEEN 2450844 AND 2451270
      AND web_sales.ws_net_paid_inc_ship > 1000
      AND inventory.inv_quantity_on_hand > 0
      AND income_band.ib_lower_bound >= 50000
)
SELECT
    store_id,
    p_promo_id,
    cp_catalog_page_id,
    wp_web_page_id,
    sm_ship_mode_id,
    SUM(ss_net_profit)               AS total_profit,
    SUM(ss_quantity)                 AS total_quantity,
    SUM(ws_net_paid_inc_ship)        AS total_web_paid,
    SUM(cr_return_amount)            AS total_return_amount,
    RANK() OVER (ORDER BY SUM(ss_net_profit) DESC) AS profit_rank,
    CASE WHEN SUM(ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category
FROM joined_data
GROUP BY CUBE (store_id, p_promo_id, cp_catalog_page_id, wp_web_page_id, sm_ship_mode_id)
HAVING SUM(ss_net_profit) IS NOT NULL
ORDER BY profit_rank
LIMIT 100
