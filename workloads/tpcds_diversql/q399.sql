WITH filtered_sales AS (
    SELECT
        ws_warehouse_sk,
        ws_bill_hdemo_sk,
        SUM(ws_net_paid_inc_tax) AS total_paid,
        COUNT(*) AS order_cnt
    FROM web_sales
    WHERE ws_net_paid_inc_tax > 500
      AND ws_ext_wholesale_cost < 3000
      AND ws_quantity >= 1
      AND ws_ship_hdemo_sk IN (
          SELECT hd_demo_sk
          FROM household_demographics
          WHERE hd_income_band_sk IN (5, 9, 15)
      )
      AND ws_bill_hdemo_sk IN (
          SELECT hd_demo_sk
          FROM household_demographics
          WHERE hd_buy_potential = '5001-10000'
      )
    GROUP BY ws_warehouse_sk, ws_bill_hdemo_sk
),
eligible_warehouses AS (
    SELECT w_warehouse_sk
    FROM warehouse
    WHERE w_state = 'CA'
      AND w_country = 'United States'
      AND w_gmt_offset BETWEEN -5.00 AND 0.00
),
common_warehouses AS (
    SELECT ws_warehouse_sk
    FROM filtered_sales
    INTERSECT
    SELECT w_warehouse_sk
    FROM eligible_warehouses
),
joined_data AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        f.total_paid,
        f.order_cnt,
        CASE WHEN f.total_paid > 10000 THEN 'High' ELSE 'Low' END AS revenue_category
    FROM filtered_sales f
    JOIN warehouse w
        ON f.ws_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd
        ON f.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE f.ws_warehouse_sk IN (SELECT ws_warehouse_sk FROM common_warehouses)
      AND hd.hd_dep_count >= 2
      AND hd.hd_vehicle_count <= 3
)
SELECT
    w_warehouse_id,
    w_city,
    total_paid,
    order_cnt,
    revenue_category
FROM joined_data
ORDER BY total_paid DESC
LIMIT 100
