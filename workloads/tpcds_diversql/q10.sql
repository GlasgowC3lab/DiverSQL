WITH store_part AS (
    SELECT DISTINCT
        hd.hd_demo_sk,
        CASE WHEN hd.hd_dep_count >= 5 THEN 'Big' ELSE 'Small' END AS dep_category
    FROM store_sales ss
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_ext_sales_price > 1000
      AND ss.ss_quantity >= 1
),
web_part AS (
    SELECT DISTINCT
        hd.hd_demo_sk,
        CASE WHEN hd.hd_dep_count >= 5 THEN 'Big' ELSE 'Small' END AS dep_category
    FROM web_sales ws
    JOIN household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_ext_sales_price > 1000
      AND ws.ws_quantity >= 1
)
SELECT *
FROM store_part
INTERSECT
SELECT *
FROM web_part
ORDER BY hd_demo_sk, dep_category
LIMIT 100
