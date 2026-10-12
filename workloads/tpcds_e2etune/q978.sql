WITH inv_agg AS (
    SELECT
        inv.inv_item_sk,
        w.w_state,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM inventory inv
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY inv.inv_item_sk, w.w_state
    HAVING SUM(inv.inv_quantity_on_hand) > 500
)
SELECT
    i.i_category AS category,
    inv_agg.w_state AS state,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_quantity) AS avg_return_quantity,
    SUM(inv_agg.total_inventory_on_hand) AS total_inventory_on_hand,
    RANK() OVER (ORDER BY SUM(sr.sr_return_amt) DESC) AS return_amount_rank
FROM store_returns sr
JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN inv_agg ON i.i_item_sk = inv_agg.inv_item_sk
WHERE
    td.t_hour BETWEEN 9 AND 17
    AND hd.hd_buy_potential = '1001-5000'
    AND hd.hd_vehicle_count >= 2
GROUP BY
    i.i_category,
    inv_agg.w_state
HAVING
    SUM(sr.sr_return_amt) > 1000
ORDER BY
    total_return_amount DESC
LIMIT 100
