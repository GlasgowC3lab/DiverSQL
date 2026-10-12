WITH ss_agg AS (
    SELECT ss_item_sk,
           SUM(ss_ext_sales_price) AS total_item_sales,
           COUNT(*) AS sales_cnt
    FROM tpcds.store_sales TABLESAMPLE BERNOULLI (10)
    GROUP BY ss_item_sk
),
ws_agg AS (
    SELECT ws_item_sk,
           SUM(ws_ext_sales_price) AS total_web_sales,
           COUNT(*) AS web_sales_cnt
    FROM tpcds.web_sales
    GROUP BY ws_item_sk
)
SELECT
    item_category,
    store_state,
    page_type,
    sales_type,
    total_sales,
    sales_cnt
FROM (
    SELECT
        i.i_category AS item_category,
        s.s_state AS store_state,
        CAST(NULL AS varchar) AS page_type,
        'store' AS sales_type,
        SUM(ss_agg.total_item_sales) AS total_sales,
        SUM(ss_agg.sales_cnt) AS sales_cnt
    FROM tpcds.store_sales ss
    JOIN ss_agg ON ss.ss_item_sk = ss_agg.ss_item_sk
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.customer c1 ON ss.ss_customer_sk = c1.c_customer_sk
    JOIN tpcds.customer_demographics cd1 ON ss.ss_cdemo_sk = cd1.cd_demo_sk
    JOIN tpcds.household_demographics hd1 ON ss.ss_hdemo_sk = hd1.hd_demo_sk
    JOIN tpcds.income_band ib1 ON hd1.hd_income_band_sk = ib1.ib_income_band_sk
    LEFT JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE NOT EXISTS (
        SELECT 1 FROM tpcds.store_returns sr2
        WHERE sr2.sr_ticket_number = ss.ss_ticket_number
          AND sr2.sr_return_quantity > 0
    )
    GROUP BY GROUPING SETS (
        (i.i_category, s.s_state),
        (i.i_category),
        (s.s_state),
        ()
    )
) UNION DISTINCT
SELECT
    item_category,
    store_state,
    page_type,
    sales_type,
    total_sales,
    sales_cnt
FROM (
    SELECT
        i.i_category AS item_category,
        CAST(NULL AS varchar) AS store_state,
        wp.wp_type AS page_type,
        'web' AS sales_type,
        SUM(ws_agg.total_web_sales) AS total_sales,
        SUM(ws_agg.web_sales_cnt) AS sales_cnt
    FROM tpcds.web_sales ws
    JOIN ws_agg ON ws.ws_item_sk = ws_agg.ws_item_sk
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.customer c2 ON wp.wp_customer_sk = c2.c_customer_sk
    JOIN tpcds.customer_demographics cd2 ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
    JOIN tpcds.household_demographics hd2 ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
    JOIN tpcds.income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
    WHERE NOT EXISTS (
        SELECT 1 FROM tpcds.web_sales ws2
        WHERE ws2.ws_order_number = ws.ws_order_number
          AND ws2.ws_quantity = 0
    )
    GROUP BY GROUPING SETS (
        (i.i_category, wp.wp_type),
        (i.i_category),
        (wp.wp_type),
        ()
    )
) 
LIMIT 100
