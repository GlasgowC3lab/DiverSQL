WITH profit_by_demo AS (
    SELECT
        hd_bill.hd_buy_potential,
        hd_bill.hd_vehicle_count,
        hd_ship.hd_dep_count,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_quantity) AS avg_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM web_sales ws
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    WHERE hd_bill.hd_income_band_sk >= 3
      AND ws.ws_web_page_sk IN (2557, 831)
      AND ws.ws_quantity > 0
    GROUP BY hd_bill.hd_buy_potential, hd_bill.hd_vehicle_count, hd_ship.hd_dep_count
    HAVING SUM(ws.ws_net_profit) > 5000
)
SELECT
    hd_buy_potential,
    hd_vehicle_count,
    hd_dep_count,
    total_profit,
    avg_quantity,
    distinct_orders,
    total_discount,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM profit_by_demo
ORDER BY total_profit DESC
LIMIT 10
