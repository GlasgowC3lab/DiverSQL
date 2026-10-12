WITH base AS (
    SELECT
        d.d_year,
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        ss.ss_quantity,
        ss.ss_net_profit,
        hd.hd_income_band_sk,
        cd.cd_gender,
        cp.cp_catalog_page_id,
        sm.sm_type,
        ws.ws_order_number,
        -- additional columns to keep the join chain alive
        ss.ss_sold_date_sk,
        sr.sr_ticket_number,
        inv.inv_quantity_on_hand,
        p.p_discount_active,
        wp.wp_url,
        wsite.web_name
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                               AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.item i ON i.i_item_sk = ss.ss_item_sk
    JOIN tpcds.promotion p ON p.p_promo_sk = ss.ss_promo_sk
                           AND p.p_item_sk = i.i_item_sk
    JOIN tpcds.customer_demographics cd ON cd.cd_demo_sk = ss.ss_cdemo_sk
    JOIN tpcds.household_demographics hd ON hd.hd_demo_sk = ss.ss_hdemo_sk
    JOIN tpcds.inventory inv ON inv.inv_date_sk = d.d_date_sk
                              AND inv.inv_item_sk = i.i_item_sk
    JOIN tpcds.catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN tpcds.web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                             AND ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                               AND wr.wr_order_number = ws.ws_order_number
    JOIN tpcds.web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
    JOIN tpcds.web_site wsite ON wsite.web_site_sk = ws.ws_web_site_sk
    JOIN tpcds.ship_mode sm ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
),
agg AS (
    SELECT
        d_year,
        i_item_sk,
        i_product_name,
        i_current_price,
        hd_income_band_sk,
        cd_gender,
        cp_catalog_page_id,
        sm_type,
        CASE WHEN i_current_price > (
                SELECT avg(i2.i_current_price)
                FROM tpcds.item i2
            ) THEN 'Above Avg' ELSE 'Below Avg' END AS price_category,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_profit
    FROM base
    WHERE d_year = 2000
      AND i_current_price > 20
      AND hd_income_band_sk BETWEEN 5 AND 10
    GROUP BY
        d_year,
        i_item_sk,
        i_product_name,
        i_current_price,
        hd_income_band_sk,
        cd_gender,
        cp_catalog_page_id,
        sm_type,
        CASE WHEN i_current_price > (
                SELECT avg(i2.i_current_price)
                FROM tpcds.item i2
            ) THEN 'Above Avg' ELSE 'Below Avg' END
)
SELECT
    d_year,
    i_item_sk,
    i_product_name,
    i_current_price,
    hd_income_band_sk,
    cd_gender,
    cp_catalog_page_id,
    sm_type,
    price_category,
    total_quantity,
    total_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY profit_rank
LIMIT 100
