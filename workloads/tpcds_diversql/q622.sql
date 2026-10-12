WITH
    -- Catalog sales enriched with many dimensions and a promotion EXISTS filter
    catalog_sales_agg AS (
        SELECT
            cs.cs_order_number        AS order_id,
            cs.cs_sold_date_sk        AS sold_date_sk,
            cs.cs_item_sk             AS item_sk,
            i.i_category,
            d.cd_gender,
            hd.hd_income_band_sk,
            w.w_warehouse_id,
            p.p_promo_id,
            t.t_hour,
            cs.cs_net_paid           AS net_paid,
            cc.cc_name               AS call_center_name,
            cp.cp_department         AS catalog_department
        FROM catalog_sales cs
        JOIN item i                     ON cs.cs_item_sk      = i.i_item_sk
        JOIN customer_demographics d    ON cs.cs_bill_cdemo_sk = d.cd_demo_sk
        JOIN household_demographics hd  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN warehouse w                ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN promotion p                ON cs.cs_promo_sk     = p.p_promo_sk
        JOIN time_dim t                 ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN call_center cc             ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE EXISTS (
            SELECT 1 FROM promotion p_sub
            WHERE p_sub.p_item_sk = cs.cs_item_sk
              AND p_sub.p_discount_active = 'Y'
        )
    ),
    -- Web sales enriched with the same set of dimensions (item reused under a different alias)
    web_sales_agg AS (
        SELECT
            ws.ws_order_number        AS order_id,
            ws.ws_sold_date_sk        AS sold_date_sk,
            ws.ws_item_sk             AS item_sk,
            i2.i_category,
            d2.cd_gender,
            hd2.hd_income_band_sk,
            w2.w_warehouse_id,
            p2.p_promo_id,
            t2.t_hour,
            ws.ws_net_paid           AS net_paid,
            NULL                     AS call_center_name,
            NULL                     AS catalog_department
        FROM web_sales ws
        JOIN item i2                    ON ws.ws_item_sk      = i2.i_item_sk
        JOIN customer_demographics d2   ON ws.ws_bill_cdemo_sk = d2.cd_demo_sk
        JOIN household_demographics hd2 ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
        JOIN warehouse w2               ON ws.ws_warehouse_sk = w2.w_warehouse_sk
        JOIN promotion p2               ON ws.ws_promo_sk     = p2.p_promo_sk
        JOIN time_dim t2                ON ws.ws_sold_time_sk = t2.t_time_sk
        WHERE i2.i_current_price > 15
    ),
    -- Store returns enriched; income band is brought in via household_demographics
    store_returns_agg AS (
        SELECT
            sr.sr_ticket_number       AS order_id,
            sr.sr_returned_date_sk    AS sold_date_sk,
            sr.sr_item_sk             AS item_sk,
            i3.i_category,
            cd3.cd_gender,
            hd3.hd_income_band_sk,
            ib.ib_lower_bound        AS income_lower,
            ib.ib_upper_bound        AS income_upper,
            t3.t_hour,
            sr.sr_return_amt         AS net_paid,
            NULL                     AS call_center_name,
            NULL                     AS catalog_department
        FROM store_returns sr
        JOIN item i3                     ON sr.sr_item_sk      = i3.i_item_sk
        JOIN customer_demographics cd3   ON sr.sr_cdemo_sk     = cd3.cd_demo_sk
        JOIN household_demographics hd3 ON sr.sr_hdemo_sk     = hd3.hd_demo_sk
        JOIN time_dim t3                ON sr.sr_return_time_sk = t3.t_time_sk
        JOIN income_band ib             ON hd3.hd_income_band_sk = ib.ib_income_band_sk
    ),
    -- Sample a fraction of inventory (used later in an IN predicate)
    inventory_sample AS (
        SELECT inv_item_sk, inv_quantity_on_hand
        FROM inventory TABLESAMPLE BERNOULLI (10)
    ),
    -- Catalog returns – we will later EXCEPT them from the full set of orders
    catalog_returns_keys AS (
        SELECT cr.cr_order_number AS order_id
        FROM catalog_returns cr
        JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
        WHERE cr.cr_return_quantity > 0
    ),
    -- Union of all sales‑like events (catalog, web, store returns), using a FULL OUTER JOIN between catalog and web
    combined_sales_raw AS (
        SELECT
            ca.order_id,
            ca.sold_date_sk,
            ca.item_sk,
            ca.i_category,
            ca.cd_gender,
            ca.hd_income_band_sk,
            ca.w_warehouse_id,
            ca.p_promo_id,
            ca.t_hour,
            ca.net_paid,
            'catalog' AS source
        FROM catalog_sales_agg ca
        FULL OUTER JOIN web_sales_agg wa ON ca.item_sk = wa.item_sk

        UNION DISTINCT

        SELECT
            wa.order_id,
            wa.sold_date_sk,
            wa.item_sk,
            wa.i_category,
            wa.cd_gender,
            wa.hd_income_band_sk,
            wa.w_warehouse_id,
            wa.p_promo_id,
            wa.t_hour,
            wa.net_paid,
            'web' AS source
        FROM web_sales_agg wa
        LEFT JOIN catalog_sales_agg ca ON ca.item_sk = wa.item_sk

        UNION DISTINCT

        SELECT
            sr.order_id,
            sr.sold_date_sk,
            sr.item_sk,
            sr.i_category,
            sr.cd_gender,
            sr.hd_income_band_sk,
            NULL AS w_warehouse_id,
            NULL AS p_promo_id,
            sr.t_hour,
            sr.net_paid,
            'store_return' AS source
        FROM store_returns_agg sr
    ),
    -- Remove any order that appears in catalog_returns (EXCEPT operator)
    all_non_returned_orders AS (
        SELECT order_id FROM combined_sales_raw
        EXCEPT
        SELECT order_id FROM catalog_returns_keys
    ),
    -- Final filtered set that also satisfies the inventory IN predicate
    filtered_sales AS (
        SELECT cs.*
        FROM combined_sales_raw cs
        JOIN all_non_returned_orders nr ON cs.order_id = nr.order_id
        WHERE cs.item_sk IN (SELECT inv_item_sk FROM inventory_sample WHERE inv_quantity_on_hand > 0)
    )
SELECT
    fs.i_category,
    COUNT(DISTINCT fs.order_id)                 AS distinct_orders,
    COUNT(DISTINCT fs.source)                  AS distinct_sources,
    SUM(fs.net_paid)                           AS total_net_paid,
    COUNT(DISTINCT CASE WHEN fs.source = 'catalog'      THEN fs.order_id END) AS catalog_orders,
    COUNT(DISTINCT CASE WHEN fs.source = 'web'          THEN fs.order_id END) AS web_orders,
    COUNT(DISTINCT CASE WHEN fs.source = 'store_return' THEN fs.order_id END) AS store_return_orders
FROM filtered_sales fs
GROUP BY fs.i_category
ORDER BY total_net_paid DESC
LIMIT 100
