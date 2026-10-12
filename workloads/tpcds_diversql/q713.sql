WITH catalog_orders AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE regexp_like(cc.cc_manager, '^Travis')
),
returned_orders AS (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
),
orders_no_return AS (
    SELECT cs_order_number FROM catalog_orders
    EXCEPT
    SELECT cr_order_number FROM returned_orders
)
SELECT
    cc.cc_call_center_id,
    CONCAT(cc.cc_city, ', ', cc.cc_state) AS call_center_location,
    substr(cc.cc_manager, 1, 10) AS manager_prefix,
    regexp_extract(cc.cc_mkt_desc, '(\\w+)', 1) AS first_word_desc,
    w.w_warehouse_id,
    w.w_city,
    d.d_year,
    COUNT(DISTINCT cs.cs_order_number) AS orders_count,
    SUM(cs.cs_net_paid) AS total_net_paid,
    (
        SELECT SUM(inv.inv_quantity_on_hand)
        FROM inventory inv
        WHERE inv.inv_warehouse_sk = w.w_warehouse_sk
    ) AS total_inventory_on_hand,
    t.month_name
FROM orders_no_return onr
JOIN catalog_sales cs ON cs.cs_order_number = onr.cs_order_number
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
CROSS JOIN (VALUES 'Jan', 'Feb', 'Mar') AS t(month_name)
WHERE w.w_warehouse_id LIKE 'AAAAA%'
  AND regexp_like(cc.cc_mkt_desc, 'electrical')
  AND cs.cs_sold_date_sk > (
        SELECT MAX(d_date_sk)
        FROM date_dim
        WHERE d_year = 1999
    )
GROUP BY
    cc.cc_call_center_id,
    cc.cc_city,
    cc.cc_state,
    cc.cc_manager,
    cc.cc_mkt_desc,
    w.w_warehouse_id,
    w.w_city,
    w.w_warehouse_sk,
    d.d_year,
    t.month_name
ORDER BY total_net_paid DESC
OFFSET 20
LIMIT 100
