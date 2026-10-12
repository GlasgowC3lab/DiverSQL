WITH cs_sample AS (
        SELECT *
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    aggregated AS (
        SELECT
            cs.cs_order_number AS order_number,
            cs.cs_item_sk AS item_sk,
            d_sold.d_date AS sold_date,
            d_ship.d_date AS ship_date,
            wh.w_warehouse_name AS warehouse_name,
            cc.cc_name AS call_center_name,
            SUM(cs.cs_net_paid) AS total_net_paid,
            SUM(cs.cs_net_profit) AS total_net_profit,
            SUM(cs.cs_quantity) AS total_quantity,
            SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_return_qty,
            MAX(sr.sr_return_amt) AS max_return_amt
        FROM cs_sample cs
        JOIN date_dim d_sold
            ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN date_dim d_ship
            ON cs.cs_ship_date_sk = d_ship.d_date_sk
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse wh
            ON cs.cs_warehouse_sk = wh.w_warehouse_sk
        JOIN time_dim t_sold
            ON cs.cs_sold_time_sk = t_sold.t_time_sk
        LEFT JOIN store_returns sr
            ON sr.sr_item_sk = cs.cs_item_sk
           AND sr.sr_returned_date_sk = d_sold.d_date_sk
        LEFT JOIN inventory inv
            ON inv.inv_item_sk = cs.cs_item_sk
           AND inv.inv_date_sk = d_sold.d_date_sk
        LEFT JOIN warehouse wh_inv
            ON inv.inv_warehouse_sk = wh_inv.w_warehouse_sk
        LEFT JOIN time_dim t_return
            ON sr.sr_return_time_sk = t_return.t_time_sk
        LEFT JOIN UNNEST(split(cc.cc_hours, ',')) AS u(cc_hour_part) ON true
        WHERE EXISTS (
            SELECT 1
            FROM store_returns sr2
            WHERE sr2.sr_item_sk = cs.cs_item_sk
              AND sr2.sr_returned_date_sk = d_sold.d_date_sk
        )
        GROUP BY
            cs.cs_order_number,
            cs.cs_item_sk,
            d_sold.d_date,
            d_ship.d_date,
            wh.w_warehouse_name,
            cc.cc_name
    )
SELECT
    order_number,
    item_sk,
    sold_date,
    ship_date,
    warehouse_name,
    call_center_name,
    total_net_paid,
    total_net_profit,
    total_quantity,
    total_return_qty,
    max_return_amt,
    SUM(total_net_paid) OVER (
        PARTITION BY warehouse_name
        ORDER BY sold_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_net_paid,
    LAG(total_quantity) OVER (
        PARTITION BY warehouse_name
        ORDER BY sold_date
    ) AS prev_day_quantity
FROM aggregated
ORDER BY total_net_paid DESC, sold_date
LIMIT 100
