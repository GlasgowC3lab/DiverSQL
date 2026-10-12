/* Goal: Analyze yearly net revenue per item category and store, enriched with catalog sales, inventory, web activity and logistics information, and rank the results. */
WITH ss AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_net_paid,
        d.d_year,
        i.i_category,
        c.c_customer_id,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ca.ca_city,
        s.s_store_name,
        wp.wp_url
    FROM store_sales ss
    JOIN date_dim d           ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i               ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c           ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib       ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca  ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s              ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN web_page wp     ON wp.wp_customer_sk = c.c_customer_sk
    WHERE ss.ss_item_sk IN (
        SELECT i2.i_item_sk FROM item i2 WHERE i2.i_current_price > 100
    )
    AND ss.ss_store_sk = (
        SELECT s2.s_store_sk FROM store s2 WHERE s2.s_store_name = 'Store 1' LIMIT 1
    )
),
cat_agg AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        SUM(cs.cs_ext_sales_price)               AS total_catalog_sales,
        MAX(sm.sm_type)                           AS ship_mode_type,
        MAX(cp.cp_type)                           AS catalog_page_type,
        MAX(cc.cc_class)                          AS call_center_class
    FROM ss
    JOIN catalog_sales cs       ON cs.cs_sold_date_sk = ss.ss_sold_date_sk
    JOIN call_center cc          ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp         ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY ss.ss_sold_date_sk, ss.ss_item_sk
),
inv_agg AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        MAX(w.w_warehouse_name)      AS warehouse_name
    FROM ss
    JOIN inventory inv           ON inv.inv_item_sk = ss.ss_item_sk
    JOIN date_dim d_inv          ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN warehouse w             ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d_inv.d_year = (SELECT d2.d_year FROM date_dim d2 WHERE d2.d_date_sk = ss.ss_sold_date_sk)
    GROUP BY ss.ss_sold_date_sk, ss.ss_item_sk
),
web_site_agg AS (
    SELECT
        ss.ss_sold_date_sk,
        MAX(ws.web_name) AS web_site_name
    FROM ss
    JOIN web_site ws ON ws.web_open_date_sk = ss.ss_sold_date_sk
    GROUP BY ss.ss_sold_date_sk
)
SELECT
    ROW_NUMBER() OVER (ORDER BY agg.total_net_paid DESC) AS row_num,
    agg.d_year,
    agg.i_category,
    agg.s_store_name,
    agg.total_net_paid,
    agg.total_catalog_sales,
    agg.total_inventory,
    agg.ship_mode_type,
    agg.catalog_page_type,
    agg.call_center_class,
    agg.web_site_name,
    agg.txn_cnt
FROM (
    SELECT
        ss.d_year,
        ss.i_category,
        ss.s_store_name,
        SUM(ss.ss_net_paid)                AS total_net_paid,
        SUM(ca.total_catalog_sales)        AS total_catalog_sales,
        SUM(ia.total_inventory)            AS total_inventory,
        MAX(ca.ship_mode_type)             AS ship_mode_type,
        MAX(ca.catalog_page_type)          AS catalog_page_type,
        MAX(ca.call_center_class)          AS call_center_class,
        MAX(wsa.web_site_name)             AS web_site_name,
        COUNT(*)                           AS txn_cnt
    FROM ss
    LEFT JOIN cat_agg ca   ON ca.ss_sold_date_sk = ss.ss_sold_date_sk AND ca.ss_item_sk = ss.ss_item_sk
    LEFT JOIN inv_agg ia   ON ia.ss_sold_date_sk = ss.ss_sold_date_sk AND ia.ss_item_sk = ss.ss_item_sk
    LEFT JOIN web_site_agg wsa ON wsa.ss_sold_date_sk = ss.ss_sold_date_sk
    GROUP BY ss.d_year, ss.i_category, ss.s_store_name
) agg
ORDER BY agg.total_net_paid DESC
LIMIT 100
