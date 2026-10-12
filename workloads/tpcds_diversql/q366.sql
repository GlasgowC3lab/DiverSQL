WITH
  -- Filtered sales to provide a manageable base set
  sales_filtered AS (
    SELECT cs.*
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
      AND cs.cs_net_paid > 100
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
      AND cs.cs_ship_mode_sk IN (1, 2)
  ),

  -- Chain‑deep join of all seven tables (left‑deep path)
  joined AS (
    SELECT
      cs.cs_order_number,
      cs.cs_quantity,
      cs.cs_net_paid,
      cs.cs_net_profit,
      cp.cp_catalog_page_number,
      cp.cp_type,
      td.t_shift,
      td.t_am_pm,
      sm.sm_type                AS ship_type,
      w.w_warehouse_name,
      w.w_city,
      inv.inv_quantity_on_hand,
      ca.ca_state
    FROM sales_filtered cs
    JOIN catalog_page cp      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td          ON cs.cs_sold_time_sk    = td.t_time_sk
    JOIN ship_mode sm         ON cs.cs_ship_mode_sk    = sm.sm_ship_mode_sk
    JOIN warehouse w          ON cs.cs_warehouse_sk    = w.w_warehouse_sk
    FULL OUTER JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN inventory inv   ON w.w_warehouse_sk = inv.inv_warehouse_sk
  ),

  -- Two sub‑queries whose key sets will be intersected
  sub1 AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_quantity > 10 AND cs_net_profit > 50
  ),
  sub2 AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_quantity > 8 AND cs_net_paid > 200
  ),
  intersect_keys AS (
    SELECT cs_order_number FROM sub1
    INTERSECT
    SELECT cs_order_number FROM sub2
  ),

  -- Two SELECTs combined with UNION (DISTINCT) to force a de‑duplicated aggregate
  union_agg AS (
    SELECT cs.cs_warehouse_sk AS warehouse_sk, SUM(cs.cs_net_paid) AS total_paid
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450050
    GROUP BY cs.cs_warehouse_sk
    UNION
    SELECT cs.cs_warehouse_sk, SUM(cs.cs_net_paid)
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450051 AND 2450100
    GROUP BY cs.cs_warehouse_sk
  ),

  -- Final aggregation using GROUPING SETS
  final AS (
    SELECT
      w_name,
      cp_type,
      t_shift,
      ship_type,
      SUM(quantity)                AS total_quantity,
      AVG(net_paid)                AS avg_net_paid,
      COUNT(DISTINCT order_number) AS order_cnt,
      MIN(net_paid)                AS min_paid,
      MAX(net_paid)                AS max_paid
    FROM (
      SELECT
        w.w_warehouse_name AS w_name,
        cp.cp_type,
        td.t_shift,
        sm.sm_type AS ship_type,
        cs.cs_order_number AS order_number,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        ca.ca_state
      FROM catalog_sales cs
      JOIN catalog_page cp      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
      JOIN time_dim td          ON cs.cs_sold_time_sk    = td.t_time_sk
      JOIN ship_mode sm         ON cs.cs_ship_mode_sk    = sm.sm_ship_mode_sk
      JOIN warehouse w          ON cs.cs_warehouse_sk    = w.w_warehouse_sk
      FULL OUTER JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
      LEFT JOIN inventory inv   ON w.w_warehouse_sk = inv.inv_warehouse_sk
      WHERE ca.ca_state = 'CA'
        AND td.t_am_pm = 'PM'
        AND w.w_city = 'Seattle'
        AND cp.cp_type = 'monthly'
        AND cs.cs_quantity > 3
        AND cs.cs_net_paid > 50
    ) sub
    GROUP BY GROUPING SETS (
      (w_name, cp_type, t_shift, ship_type),
      (w_name, cp_type),
      (t_shift, ship_type),
      ()
    )
  )
SELECT *
FROM final
ORDER BY total_quantity DESC
OFFSET 0 FETCH NEXT 50 ROWS ONLY
