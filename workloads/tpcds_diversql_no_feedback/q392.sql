WITH base AS (
    SELECT
        cc.cc_name,
        w.w_city,
        sm.sm_type,
        hd_bill_cs.hd_buy_potential,
        cs.cs_ext_sales_price               AS cs_sales,
        ws.ws_ext_sales_price               AS ws_sales,
        wr.wr_return_amt                    AS return_amt,
        cs.cs_coupon_amt,
        ws.ws_wholesale_cost,
        cs.cs_list_price
    FROM catalog_sales cs
    RIGHT OUTER JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd_bill_cs
        ON cs.cs_bill_hdemo_sk = hd_bill_cs.hd_demo_sk
    -- Web sales facts share the same warehouse, ship mode and dimensions
    JOIN web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
       AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd_bill_ws
        ON ws.ws_bill_hdemo_sk = hd_bill_ws.hd_demo_sk
    JOIN household_demographics hd_ship_ws
        ON ws.ws_ship_hdemo_sk = hd_ship_ws.hd_demo_sk
    -- Returns linked to web sales
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    WHERE cs.cs_coupon_amt > 1000
      AND cs.cs_list_price BETWEEN 50 AND 200
      AND w.w_street_name = '7th Park'
      AND w.w_suite_number = 'Suite 480 '
      AND w.w_county = 'Oglethorpe County'
      AND ws.ws_ship_customer_sk = 7963718
      AND ws.ws_wholesale_cost < 70
      AND sm.sm_type = 'AIR'
),
agg AS (
    SELECT
        cc_name,
        w_city,
        sm_type,
        hd_buy_potential,
        SUM(cs_sales)        AS total_catalog_sales,
        SUM(ws_sales)        AS total_web_sales,
        SUM(return_amt)      AS total_returns,
        COUNT(*)             AS cnt_rows,
        AVG(cs_coupon_amt)   AS avg_coupon_amt,
        MIN(ws_wholesale_cost) AS min_wholesale_cost,
        MAX(cs_list_price)   AS max_list_price
    FROM base
    GROUP BY ROLLUP (cc_name, w_city, sm_type, hd_buy_potential)
)
SELECT
    cc_name,
    w_city,
    sm_type,
    hd_buy_potential,
    total_catalog_sales,
    total_web_sales,
    total_returns,
    cnt_rows,
    avg_coupon_amt,
    min_wholesale_cost,
    max_list_price,
    ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY total_catalog_sales DESC) AS sales_rank
FROM agg
ORDER BY total_catalog_sales DESC
LIMIT 100
