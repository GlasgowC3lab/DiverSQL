SELECT
    wr.wr_order_number,
    hd.hd_buy_potential,
    CASE
        WHEN hd.hd_vehicle_count > 2 THEN 'High'
        WHEN hd.hd_vehicle_count = 2 THEN 'Medium'
        ELSE 'Low'
    END AS vehicle_category,
    wr.wr_return_amt * (1 + wr.wr_return_tax) AS total_return_inc_tax,
    wr.wr_return_quantity * 2 AS double_quantity,
    COALESCE(wr.wr_return_ship_cost, 0) - 5.00 AS net_ship_cost,
    CONCAT('HD_', CAST(hd.hd_demo_sk AS VARCHAR)) AS hd_key_str,
    (wr.wr_return_quantity * wr.wr_return_amt) / NULLIF(wr.wr_return_quantity, 0) AS avg_return_per_item,
    CASE
        WHEN wr.wr_return_amt > 1000.00 THEN 'LargeLoss'
        ELSE 'SmallLoss'
    END AS loss_category
FROM web_returns wr
JOIN household_demographics hd
    ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE wr.wr_returned_date_sk = 2451878
  AND hd.hd_income_band_sk = 6
