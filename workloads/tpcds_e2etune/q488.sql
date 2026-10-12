WITH sold_sales AS (
    SELECT
        ws.ws_warehouse_sk AS warehouse_id,
        d_sold.d_fy_quarter_seq AS fy_quarter_seq,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount
    FROM web_sales ws
    INNER JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_fy_year = 1902
      AND d_sold.d_quarter_name = '1902Q1'
    GROUP BY ws.ws_warehouse_sk, d_sold.d_fy_quarter_seq
),
inv_summary AS (
    SELECT
        inv.inv_warehouse_sk AS warehouse_id,
        d_inv.d_fy_quarter_seq AS fy_quarter_seq,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory inv
    INNER JOIN date_dim d_inv
        ON inv.inv_date_sk = d_inv.d_date_sk
    WHERE d_inv.d_fy_year = 1902
    GROUP BY inv.inv_warehouse_sk, d_inv.d_fy_quarter_seq
)
SELECT
    s.fy_quarter_seq,
    s.warehouse_id,
    s.total_net_profit,
    s.total_quantity_sold,
    i.total_inventory_qty,
    CASE WHEN i.total_inventory_qty > 0 THEN s.total_net_profit / i.total_inventory_qty END AS profit_per_inventory,
    RANK() OVER (PARTITION BY s.fy_quarter_seq ORDER BY s.total_net_profit DESC) AS profit_rank
FROM sold_sales s
INNER JOIN inv_summary i
    ON s.warehouse_id = i.warehouse_id
   AND s.fy_quarter_seq = i.fy_quarter_seq
WHERE s.total_net_profit > 10000
ORDER BY s.fy_quarter_seq, profit_rank
