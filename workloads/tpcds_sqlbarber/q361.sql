SELECT
    d.d_year,
    cc.cc_name,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    inv.sample_inventory_qty
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
JOIN (
    SELECT inv_date_sk, inv_quantity_on_hand AS sample_inventory_qty
    FROM (
        SELECT inv_date_sk,
               inv_quantity_on_hand,
               ROW_NUMBER() OVER (PARTITION BY inv_date_sk ORDER BY inv_quantity_on_hand DESC) AS rn
        FROM inventory
    ) t
    WHERE rn = 1
) inv ON inv.inv_date_sk = d.d_date_sk
WHERE d.d_year = 1914
GROUP BY d.d_year, cc.cc_name, d.d_date_sk, inv.sample_inventory_qty
HAVING SUM(ws.ws_ext_sales_price) > 16739.45
