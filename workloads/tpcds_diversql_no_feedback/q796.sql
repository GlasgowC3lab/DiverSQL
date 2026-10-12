WITH sales_a AS (
      SELECT
        sm.sm_type AS ship_type,
        w.w_state AS state,
        cs.cs_ext_sales_price AS sales,
        cs.cs_net_profit AS profit,
        1 AS order_cnt
      FROM catalog_sales cs
      JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
      WHERE sm.sm_type = 'REGULAR'
        AND w.w_county = 'San Miguel County'
        AND cs.cs_ext_wholesale_cost > 2000
    ),
    sales_b AS (
      SELECT
        sm.sm_type AS ship_type,
        w.w_state AS state,
        cs.cs_ext_sales_price AS sales,
        cs.cs_net_profit AS profit,
        1 AS order_cnt
      FROM catalog_sales cs
      JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
      WHERE sm.sm_type = 'EXPRESS'
        AND w.w_gmt_offset = -5.00
        AND cs.cs_ext_wholesale_cost <= 2000
    ),
    union_sales AS (
      SELECT * FROM sales_a
      UNION ALL
      SELECT * FROM sales_b
    )
SELECT
  ship_type,
  state,
  SUM(sales) AS total_sales,
  SUM(profit) AS total_profit,
  SUM(order_cnt) AS total_orders
FROM union_sales
GROUP BY ROLLUP (ship_type, state)
ORDER BY ship_type, state
LIMIT 100
