WITH sampled_inventory AS (
    SELECT inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
    FROM inventory TABLESAMPLE BERNOULLI (10)
)
SELECT
    cc.cc_name,
    cp.cp_department,
    i.i_category,
    w.w_state,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_net_profit) AS avg_profit,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    MIN(cs.cs_quantity) AS min_qty,
    MAX(cs.cs_quantity) AS max_qty,
    SUM(CASE WHEN cs.cs_quantity > 10 THEN cs.cs_ext_sales_price ELSE 0 END) AS high_qty_sales
FROM
    catalog_sales cs
    FULL OUTER JOIN item i ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    INNER JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    INNER JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    INNER JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN sampled_inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE
    cc.cc_state = 'CA'
    AND cp.cp_department = 'Electronics'
    AND i.i_brand = 'Brand#12'
    AND cs.cs_quantity > 5
    AND cs.cs_net_profit > 0
    AND w.w_state = 'TX'
    AND EXISTS (
        SELECT 1 FROM inventory inv2
        WHERE inv2.inv_item_sk = cs.cs_item_sk
          AND inv2.inv_quantity_on_hand > 0
    )
GROUP BY
    cc.cc_name,
    cp.cp_department,
    i.i_category,
    w.w_state
UNION DISTINCT
SELECT
    cc.cc_name,
    cp.cp_department,
    i.i_category,
    w.w_state,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_net_profit) AS avg_profit,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    MIN(cs.cs_quantity) AS min_qty,
    MAX(cs.cs_quantity) AS max_qty,
    SUM(CASE WHEN cs.cs_quantity > 20 THEN cs.cs_ext_sales_price ELSE 0 END) AS high_qty_sales
FROM
    catalog_sales cs
    FULL OUTER JOIN item i ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    INNER JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    INNER JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    INNER JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN sampled_inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE
    cc.cc_state = 'NY'
    AND cp.cp_department = 'Books'
    AND i.i_brand = 'Brand#45'
    AND cs.cs_quantity BETWEEN 1 AND 3
    AND cs.cs_net_profit < 0
    AND w.w_state = 'FL'
    AND EXISTS (
        SELECT 1 FROM inventory inv2
        WHERE inv2.inv_item_sk = cs.cs_item_sk
          AND inv2.inv_quantity_on_hand < 100
    )
GROUP BY
    cc.cc_name,
    cp.cp_department,
    i.i_category,
    w.w_state
HAVING
    SUM(cs.cs_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
