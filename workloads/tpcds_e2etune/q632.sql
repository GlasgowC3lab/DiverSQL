WITH sales_returns AS (
    SELECT
        cs.cs_warehouse_sk,
        cr.cr_returning_hdemo_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_net_profit,
        cr.cr_net_loss,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_returned_date_sk,
        cr.cr_return_quantity
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450900 AND 2451100
),
inventory_agg AS (
    SELECT inv_warehouse_sk, SUM(inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    hd.hd_income_band_sk,
    SUM(sr.cs_net_profit) AS total_sales_profit,
    SUM(sr.cr_net_loss) AS total_return_loss,
    SUM(sr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS total_returns,
    AVG(sr.cr_return_tax) AS avg_return_tax,
    COALESCE(ia.total_inventory_qty, 0) AS total_inventory_qty,
    (SUM(sr.cs_net_profit) - SUM(sr.cr_net_loss)) AS net_impact,
    RANK() OVER (ORDER BY (SUM(sr.cs_net_profit) - SUM(sr.cr_net_loss)) DESC) AS warehouse_rank
FROM sales_returns sr
JOIN household_demographics hd
    ON sr.cr_returning_hdemo_sk = hd.hd_demo_sk
JOIN warehouse w
    ON sr.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN inventory_agg ia
    ON w.w_warehouse_sk = ia.inv_warehouse_sk
GROUP BY w.w_warehouse_id, w.w_city, hd.hd_income_band_sk, ia.total_inventory_qty
HAVING SUM(sr.cr_return_amount) > 1000
ORDER BY net_impact DESC
LIMIT 10
