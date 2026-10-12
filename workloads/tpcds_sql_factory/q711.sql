WITH ship_hh_sales AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS profit_on_date,
        SUM(ws.ws_ext_sales_price) AS sales_on_date,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM web_sales ws
    JOIN household_demographics hd ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY hd.hd_demo_sk, hd.hd_dep_count, hd.hd_vehicle_count, hd.hd_buy_potential,
             ib.ib_lower_bound, ib.ib_upper_bound, ws.ws_sold_date_sk
),
hh_cumulative AS (
    SELECT
        hd_demo_sk,
        hd_dep_count,
        hd_vehicle_count,
        hd_buy_potential,
        ib_lower_bound,
        ib_upper_bound,
        ws_sold_date_sk,
        profit_on_date,
        sales_on_date,
        avg_sales_price,
        SUM(profit_on_date) OVER (PARTITION BY hd_demo_sk ORDER BY ws_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
    FROM ship_hh_sales
)
SELECT
    hd_demo_sk,
    hd_dep_count,
    hd_vehicle_count,
    CASE
        WHEN hd_vehicle_count = 0 THEN 'NoVehicle'
        WHEN hd_vehicle_count <= 2 THEN 'FewVehicles'
        ELSE 'ManyVehicles'
    END AS vehicle_category,
    ib_lower_bound,
    ib_upper_bound,
    ws_sold_date_sk,
    profit_on_date,
    cumulative_profit,
    RANK() OVER (ORDER BY cumulative_profit DESC) AS household_profit_rank,
    DENSE_RANK() OVER (ORDER BY hd_dep_count DESC) AS dep_dense_rank
FROM hh_cumulative
WHERE hd_dep_count >= 2
ORDER BY household_profit_rank
LIMIT 10
