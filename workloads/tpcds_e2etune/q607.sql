SELECT
    cc.cc_name,
    cc.cc_state,
    ib.ib_income_band_sk,
    SUM(inv.inv_quantity_on_hand) AS total_qty,
    AVG(itm.i_current_price) AS avg_price,
    SUM(itm.i_current_price * inv.inv_quantity_on_hand) / NULLIF(SUM(inv.inv_quantity_on_hand), 0) AS weighted_avg_price,
    RANK() OVER (ORDER BY SUM(inv.inv_quantity_on_hand) DESC) AS qty_rank
FROM
    call_center cc
    JOIN inventory inv ON inv.inv_date_sk = cc.cc_open_date_sk
    JOIN item itm ON inv.inv_item_sk = itm.i_item_sk
    JOIN income_band ib ON itm.i_wholesale_cost BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
WHERE
    cc.cc_division_name IN ('pri', 'able')
    AND cc.cc_state = 'CA'
    AND itm.i_category = 'Electronics'
GROUP BY
    cc.cc_name,
    cc.cc_state,
    ib.ib_income_band_sk
HAVING
    SUM(inv.inv_quantity_on_hand) > 1000
ORDER BY
    total_qty DESC
LIMIT 10
