WITH common_items AS (
        SELECT cs.cs_item_sk AS item_sk
        FROM catalog_sales cs
        INTERSECT
        SELECT ws.ws_item_sk
        FROM web_sales ws
    ),
    catalog_agg AS (
        SELECT
            cs.cs_item_sk,
            SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
            COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
            AVG(cs.cs_quantity) AS avg_qty,
            MAX(cs.cs_net_paid_inc_ship) AS max_net_paid
        FROM catalog_sales cs
        JOIN common_items ci ON cs.cs_item_sk = ci.item_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        WHERE p.p_discount_active = 'Y'
          AND cp.cp_type = 'HOME'
          AND sm.sm_type = 'AIR'
          AND w.w_state = 'CA'
        GROUP BY cs.cs_item_sk
    ),
    web_agg AS (
        SELECT
            ws.ws_item_sk,
            SUM(ws.ws_net_paid_inc_ship) AS total_web_net_paid,
            COUNT(*) AS web_transactions
        FROM web_sales ws
        JOIN common_items ci ON ws.ws_item_sk = ci.item_sk
        GROUP BY ws.ws_item_sk
    ),
    full_sales AS (
        SELECT
            COALESCE(ca.cs_item_sk, wa.ws_item_sk) AS item_sk,
            ca.total_net_paid,
            ca.orders_cnt,
            ca.avg_qty,
            ca.max_net_paid,
            wa.total_web_net_paid,
            wa.web_transactions
        FROM catalog_agg ca
        FULL OUTER JOIN web_agg wa
            ON ca.cs_item_sk = wa.ws_item_sk
    ),
    store_agg AS (
        SELECT
            ss.ss_item_sk,
            SUM(ss.ss_net_paid_inc_tax) AS store_net_paid,
            COUNT(*) AS store_transactions
        FROM store_sales ss
        JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
        WHERE td.t_hour BETWEEN 10 AND 16
          AND ss.ss_quantity > 1
        GROUP BY ss.ss_item_sk
    ),
    returns_agg AS (
        SELECT
            cr.cr_item_sk,
            SUM(cr.cr_return_amount) AS total_return_amount,
            COUNT(*) AS return_cnt
        FROM catalog_returns cr
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        WHERE cc.cc_country = 'United States'
          AND cr.cr_return_quantity > 0
        GROUP BY cr.cr_item_sk
    ),
    inventory_latest AS (
        SELECT
            inv.inv_item_sk,
            inv.inv_quantity_on_hand
        FROM inventory inv
        WHERE inv.inv_quantity_on_hand > 0
    )
SELECT
    fs.item_sk,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    fs.total_net_paid,
    fs.total_web_net_paid,
    sa.store_net_paid,
    ra.total_return_amount,
    il.inv_quantity_on_hand,
    CASE
        WHEN COALESCE(fs.total_net_paid, 0) + COALESCE(fs.total_web_net_paid, 0) > 20000 THEN 'HIGH'
        ELSE 'LOW'
    END AS revenue_category,
    COUNT(*) OVER (PARTITION BY i.i_brand_id) AS brand_item_count
FROM full_sales fs
LEFT JOIN store_agg sa ON fs.item_sk = sa.ss_item_sk
LEFT JOIN returns_agg ra ON fs.item_sk = ra.cr_item_sk
LEFT JOIN inventory_latest il ON fs.item_sk = il.inv_item_sk
JOIN item i ON fs.item_sk = i.i_item_sk
WHERE i.i_manufact_id = 460
  AND i.i_class_id IN (4, 10)
  AND i.i_color = 'RED'
  AND i.i_size = 'M'
  AND i.i_units = 'EA'
ORDER BY revenue_category DESC, fs.total_net_paid DESC NULLS LAST
LIMIT 100
