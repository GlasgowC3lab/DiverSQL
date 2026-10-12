WITH sales_agg AS (
    SELECT
        ws.ws_order_number AS order_number,
        d.d_year AS year,
        w.w_warehouse_id AS warehouse_id,
        ws.ws_net_paid AS net_paid,
        CASE WHEN ws.ws_quantity >= 20 THEN 'Bulk' ELSE 'Regular' END AS order_type,
        (
            SELECT SUM(inv.inv_quantity_on_hand)
            FROM inventory inv
            WHERE inv.inv_warehouse_sk = ws.ws_warehouse_sk
              AND inv.inv_date_sk = ws.ws_sold_date_sk
        ) AS inventory_on_day
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND w.w_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_order_number = ws.ws_order_number
      )
)
SELECT
    order_number,
    year,
    warehouse_id,
    net_paid,
    order_type,
    inventory_on_day
FROM sales_agg
WHERE net_paid > 1000

UNION

SELECT
    ws.ws_order_number AS order_number,
    d.d_year AS year,
    w.w_warehouse_id AS warehouse_id,
    ws.ws_net_paid AS net_paid,
    CASE WHEN ws.ws_quantity >= 20 THEN 'Bulk' ELSE 'Regular' END AS order_type,
    (
        SELECT SUM(inv.inv_quantity_on_hand)
        FROM inventory inv
        WHERE inv.inv_warehouse_sk = ws.ws_warehouse_sk
          AND inv.inv_date_sk = ws.ws_sold_date_sk
    ) AS inventory_on_day
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE d.d_year = 2001
  AND w.w_state = 'NY'
  AND EXISTS (
      SELECT 1
      FROM web_returns wr
      WHERE wr.wr_order_number = ws.ws_order_number
        AND wr.wr_return_amt > 0
  )
  AND ws.ws_net_paid > 1000

ORDER BY year DESC, net_paid DESC
