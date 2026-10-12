WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ws.ws_ship_mode_sk,
        ws.ws_ship_hdemo_sk,
        cd_bill.cd_education_status,
        cd_bill.cd_marital_status,
        cd_bill.cd_purchase_estimate,
        hd_ship.hd_vehicle_count
    FROM web_sales ws
    INNER JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    INNER JOIN household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    WHERE cd_bill.cd_education_status = 'College'
      AND cd_bill.cd_marital_status = 'M'
      AND cd_bill.cd_purchase_estimate BETWEEN 1000 AND 2000
      AND hd_ship.hd_vehicle_count >= 2
      AND ws.ws_quantity > 1
)
SELECT
    sm.sm_carrier AS carrier,
    sm.sm_type AS ship_type,
    ib.ib_lower_bound AS lower_bound,
    ib.ib_upper_bound AS upper_bound,
    COUNT(DISTINCT fs.ws_order_number) AS num_orders,
    SUM(fs.ws_ext_sales_price) AS total_sales,
    SUM(fs.ws_ext_discount_amt) AS total_discount,
    SUM(fs.ws_net_profit) AS total_profit,
    AVG(fs.ws_quantity) AS avg_quantity,
    RANK() OVER (PARTITION BY sm.sm_carrier ORDER BY SUM(fs.ws_net_profit) DESC) AS profit_rank
FROM filtered_sales fs
INNER JOIN ship_mode sm
    ON fs.ws_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN household_demographics hd_ship
    ON fs.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
INNER JOIN income_band ib
    ON hd_ship.hd_income_band_sk = ib.ib_income_band_sk
WHERE sm.sm_type = 'AIR'
GROUP BY sm.sm_carrier, sm.sm_type, ib.ib_lower_bound, ib.ib_upper_bound
HAVING COUNT(DISTINCT fs.ws_order_number) >= 10
ORDER BY total_profit DESC
LIMIT 50
