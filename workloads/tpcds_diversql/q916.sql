WITH inv_agg AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_date_sk = 2450969
      AND inv_quantity_on_hand > 0
      AND inv_warehouse_sk IN (7, 2)
    GROUP BY inv_item_sk, inv_warehouse_sk
),
warehouse_inventory AS (
    SELECT ia.inv_item_sk,
           ia.inv_warehouse_sk,
           ia.total_qty_on_hand,
           w.w_warehouse_name,
           w.w_warehouse_sk
    FROM inv_agg ia
    FULL OUTER JOIN warehouse w
        ON ia.inv_warehouse_sk = w.w_warehouse_sk
),
union_data AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        sm.sm_type AS ship_type,
        wi.w_warehouse_name AS warehouse_name,
        cr.cr_return_amount AS return_amount,
        cr.cr_order_number AS order_number,
        wi.total_qty_on_hand AS qty_on_hand,
        i.i_item_sk AS item_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse_inventory wi ON cr.cr_warehouse_sk = wi.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE cr.cr_return_amount > 100
      AND cr.cr_return_quantity >= 1
      AND d.d_year = 2000
      AND d.d_month_seq BETWEEN 1200 AND 1300
      AND i.i_brand = 'Brand#12'
    UNION DISTINCT
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        CAST(NULL AS varchar) AS ship_type,
        wi.w_warehouse_name AS warehouse_name,
        wr.wr_return_amt AS return_amount,
        wr.wr_order_number AS order_number,
        wi.total_qty_on_hand AS qty_on_hand,
        i.i_item_sk AS item_sk
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN warehouse_inventory wi ON i.i_item_sk = wi.inv_item_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE wr.wr_return_amt > 50
      AND wr.wr_return_quantity >= 1
      AND d.d_year = 2000
      AND d.d_month_seq BETWEEN 1200 AND 1300
      AND i.i_brand = 'Brand#12'
)
SELECT
    year,
    category,
    ship_type,
    warehouse_name,
    SUM(return_amount) AS total_return_amount,
    COUNT(DISTINCT order_number) AS distinct_orders,
    AVG(qty_on_hand) AS avg_qty_on_hand
FROM union_data
WHERE item_sk IN (SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 10)
GROUP BY year, category, ship_type, warehouse_name
HAVING SUM(return_amount) > (
    SELECT AVG(cr_return_amount)
    FROM catalog_returns
    WHERE cr_returned_date_sk = 2450969
)
ORDER BY total_return_amount DESC
LIMIT 100
