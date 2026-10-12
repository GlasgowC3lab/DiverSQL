WITH
    /* Aggregated catalog sales (sampled) */
    cat_sales_agg AS (
        SELECT
            cs.cs_item_sk,
            cs.cs_sold_date_sk,
            cp.cp_catalog_page_id,
            sm.sm_type,
            p.p_promo_name,
            SUM(cs.cs_net_profit) AS total_net_profit,
            COUNT(*) AS sales_cnt
        FROM catalog_sales cs
        TABLESAMPLE BERNOULLI (10)
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
        GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk, cp.cp_catalog_page_id, sm.sm_type, p.p_promo_name
    ),
    /* Aggregated web sales */
    web_sales_agg AS (
        SELECT
            ws.ws_item_sk,
            ws.ws_sold_date_sk,
            ws.ws_web_site_sk,
            sm2.sm_type AS ship_mode_type,
            p2.p_promo_name AS promo_name,
            SUM(ws.ws_net_profit) AS total_net_profit_ws,
            COUNT(*) AS ws_sales_cnt
        FROM web_sales ws
        JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
        JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
        JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
        GROUP BY ws.ws_item_sk, ws.ws_sold_date_sk, ws.ws_web_site_sk, sm2.sm_type, p2.p_promo_name
    ),
    /* Inventory aggregated by item and date */
    inv_agg AS (
        SELECT
            inv.inv_item_sk,
            inv.inv_date_sk,
            SUM(inv.inv_quantity_on_hand) AS total_quantity
        FROM inventory inv
        GROUP BY inv.inv_item_sk, inv.inv_date_sk
    ),
    /* Promotion joined to its start date */
    promo_by_start AS (
        SELECT
            p.p_promo_sk,
            p.p_promo_name,
            d_start.d_date_sk,
            d_start.d_year AS start_year
        FROM promotion p
        JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    ),
    /* Inventory joined to its date */
    inv_by_date AS (
        SELECT
            i.inv_item_sk,
            i.total_quantity,
            d_inv.d_date_sk,
            d_inv.d_year AS inv_year
        FROM inv_agg i
        JOIN date_dim d_inv ON i.inv_date_sk = d_inv.d_date_sk
    ),
    /* Full outer join of inventory and promotion on the same calendar date */
    full_inv_promo AS (
        SELECT
            i.inv_item_sk,
            i.total_quantity,
            i.d_date_sk,
            p.p_promo_sk,
            p.p_promo_name,
            p.start_year
        FROM inv_by_date i
        FULL OUTER JOIN promo_by_start p
            ON i.d_date_sk = p.d_date_sk
    ),
    /* Orders that appear in catalog_sales but never in catalog_returns */
    catalog_orders_no_return AS (
        SELECT cs_order_number
        FROM catalog_sales
        EXCEPT
        SELECT cr_order_number
        FROM catalog_returns
    ),
    /* Web orders that have at least one return */
    web_orders_with_return AS (
        SELECT ws_order_number
        FROM web_sales
        INTERSECT
        SELECT wr_order_number
        FROM web_returns
    )
SELECT
    d.d_year,
    cp.cp_department,
    COUNT(DISTINCT cs.cs_item_sk) AS catalog_distinct_items,
    SUM(cs.cs_net_paid) AS catalog_total_paid,
    SUM(ws.ws_net_paid) AS web_total_paid,
    COALESCE(SUM(fip.total_quantity), 0) AS total_inventory_quantity,
    COUNT(DISTINCT r.r_reason_desc) AS distinct_return_reasons,
    (SELECT COUNT(*) FROM catalog_orders_no_return) AS catalog_orders_no_return_cnt,
    (SELECT COUNT(*) FROM web_orders_with_return) AS web_orders_with_return_cnt,
    (SELECT MAX(d2.d_year) FROM date_dim d2) AS max_year_in_data
FROM date_dim d
LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN full_inv_promo fip ON fip.d_date_sk = d.d_date_sk
LEFT JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
LEFT JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
LEFT JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
LEFT JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
LEFT JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
LEFT JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_catalog_page_sk = cp.cp_catalog_page_sk
    )
  AND d.d_year BETWEEN 1998 AND 2000
GROUP BY d.d_year, cp.cp_department
HAVING SUM(cs.cs_net_paid) > 50000
ORDER BY d.d_year DESC, SUM(ws.ws_net_paid) DESC
LIMIT 100
