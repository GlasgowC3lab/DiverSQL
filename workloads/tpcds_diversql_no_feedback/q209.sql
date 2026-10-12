WITH warehouse_inventory AS (
    SELECT
        'Warehouse' AS source_type,
        w.w_warehouse_sk AS id,
        w.w_warehouse_name AS name,
        SUM(i.inv_quantity_on_hand) AS metric_value
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_quarter_name = '1902Q4'
      AND w.w_country = 'United States'
      AND i.inv_warehouse_sk IN (
          SELECT w2.w_warehouse_sk
          FROM warehouse w2
          WHERE w2.w_city LIKE '%Park%'
      )
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name
),
callcenter_closed AS (
    SELECT
        'CallCenter' AS source_type,
        cc.cc_call_center_sk AS id,
        cc.cc_name AS name,
        COUNT(*) AS metric_value
    FROM call_center cc
    JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_quarter_name = '1902Q4'
      AND cc.cc_state = 'CA'
    GROUP BY cc.cc_call_center_sk, cc.cc_name
)
SELECT source_type, id, name, metric_value
FROM warehouse_inventory
UNION ALL
SELECT source_type, id, name, metric_value
FROM callcenter_closed
ORDER BY metric_value DESC, source_type
LIMIT 100
