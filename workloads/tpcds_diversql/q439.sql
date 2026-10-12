WITH base AS (
    SELECT
        cs.cs_order_number AS cs_order_number,
        cs.cs_ext_sales_price AS cs_ext_sales_price,
        cs.cs_ext_list_price AS cs_ext_list_price,
        cs.cs_quantity AS cs_quantity,
        i.i_item_id AS i_item_id,
        i.i_product_name AS i_product_name,
        i.i_current_price AS i_current_price,
        cc.cc_state AS cc_state,
        cp.cp_catalog_page_number AS cp_catalog_page_number,
        sm.sm_type AS sm_type,
        w.w_warehouse_name AS w_warehouse_name,
        ca.ca_state AS ca_state,
        cd.cd_gender AS cd_gender,
        hd.hd_vehicle_count AS hd_vehicle_count,
        wp.wp_type AS wp_type,
        inv.inv_quantity_on_hand AS inv_quantity_on_hand,
        ws.ws_quantity AS ws_quantity,
        wr.wr_return_quantity AS wr_return_quantity
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
)
SELECT
    cs_order_number,
    i_item_id,
    i_product_name,
    cs_ext_sales_price,
    CASE WHEN sm_type = 'AIR' THEN 'Air' ELSE 'Other' END AS ship_mode_category,
    ROW_NUMBER() OVER (PARTITION BY cs_order_number ORDER BY cs_ext_sales_price DESC) AS rn,
    (SELECT MAX(i_current_price) FROM item) AS max_item_price,
    CASE WHEN cs_ext_sales_price > (SELECT MAX(i_current_price) FROM item) THEN 1 ELSE 0 END AS high_price_flag
FROM base
WHERE
    cs_ext_list_price > 5000
    AND cc_state = 'CA'
    AND cp_catalog_page_number BETWEEN 5 AND 20
    AND i_current_price BETWEEN 100 AND 500
    AND sm_type = 'AIR'
    AND cs_order_number NOT IN (SELECT ws_order_number FROM web_sales WHERE ws_quantity > 10)
ORDER BY cs_ext_sales_price DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
