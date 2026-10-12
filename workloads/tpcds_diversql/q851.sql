WITH filtered AS (
    SELECT
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_ship_cost,
        ws.ws_net_profit,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_buy_potential IN ('5001-10000', '501-1000')
      AND hd.hd_vehicle_count >= 1
      AND hd.hd_dep_count BETWEEN 2 AND 8
      AND ws.ws_ext_ship_cost > 200.00
      AND ws.ws_quantity >= 2
      AND ib.ib_upper_bound <= 100000
      AND EXISTS (
          SELECT 1
          FROM income_band ib2
          WHERE ib2.ib_income_band_sk = hd.hd_income_band_sk
            AND ib2.ib_lower_bound >= 30000
      )
),
adjusted AS (
    SELECT
        f.*, 
        l.adjusted_ship_cost,
        CASE WHEN f.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
        RANK() OVER (PARTITION BY f.hd_buy_potential ORDER BY f.ws_net_profit DESC) AS profit_rank
    FROM filtered f
    CROSS JOIN LATERAL (
        SELECT f.ws_ext_ship_cost * 1.05 AS adjusted_ship_cost
    ) l
),
high_rank AS (
    SELECT ws_order_number
    FROM adjusted
    WHERE profit_rank <= 5
),
loss_orders AS (
    SELECT ws_order_number
    FROM adjusted
    WHERE profit_flag = 'Loss'
)
SELECT *
FROM (
    SELECT
        ws_order_number,
        profit_rank,
        adjusted_ship_cost,
        profit_flag
    FROM adjusted
    WHERE ws_order_number IN (SELECT ws_order_number FROM high_rank)
) inc_set
EXCEPT
SELECT ws_order_number, profit_rank, adjusted_ship_cost, profit_flag
FROM adjusted
WHERE ws_order_number IN (SELECT ws_order_number FROM loss_orders)
ORDER BY profit_rank ASC, ws_order_number
OFFSET 0 LIMIT 100
