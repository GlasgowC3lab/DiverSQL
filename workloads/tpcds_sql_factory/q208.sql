WITH store_agg AS (
    SELECT ss_hdemo_sk AS hd_demo_sk,
           SUM(ss_net_profit) AS store_net_profit,
           AVG(ss_quantity) AS store_avg_quantity
    FROM store_sales
    WHERE ss_sales_price > 100
    GROUP BY ss_hdemo_sk
),
web_agg AS (
    SELECT ws_bill_hdemo_sk AS hd_demo_sk,
           SUM(ws_net_profit) AS web_net_profit,
           AVG(ws_quantity) AS web_avg_quantity
    FROM web_sales
    WHERE ws_sales_price BETWEEN 50 AND 500
    GROUP BY ws_bill_hdemo_sk
),
ship_mode_cnt AS (
    SELECT ws_ship_hdemo_sk AS hd_demo_sk,
           COUNT(DISTINCT sm.sm_ship_mode_sk) AS distinct_ship_modes,
           COUNT(*) FILTER (WHERE sm.sm_type = 'AIR') AS air_ship_modes,
           COUNT(*) FILTER (WHERE sm.sm_type = 'GROUND') AS ground_ship_modes,
           MAX(sm.sm_contract) AS max_contract
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_carrier <> 'UNKNOWN'
    GROUP BY ws_ship_hdemo_sk
),
combined AS (
    SELECT hd.hd_demo_sk,
           hd.hd_income_band_sk,
           COALESCE(sa.store_net_profit,0) + COALESCE(wa.web_net_profit,0) AS total_net_profit,
           COALESCE(sa.store_avg_quantity,0) + COALESCE(wa.web_avg_quantity,0) AS total_avg_quantity,
           hd.hd_buy_potential,
           COALESCE(sc.distinct_ship_modes,0) AS distinct_ship_modes,
           COALESCE(sc.air_ship_modes,0) AS air_ship_modes,
           COALESCE(sc.ground_ship_modes,0) AS ground_ship_modes,
           sc.max_contract
    FROM household_demographics hd
    LEFT JOIN store_agg sa ON hd.hd_demo_sk = sa.hd_demo_sk
    LEFT JOIN web_agg wa ON hd.hd_demo_sk = wa.hd_demo_sk
    LEFT JOIN ship_mode_cnt sc ON hd.hd_demo_sk = sc.hd_demo_sk
)
SELECT hd_demo_sk,
       hd_income_band_sk,
       total_net_profit,
       total_avg_quantity,
       distinct_ship_modes,
       air_ship_modes,
       ground_ship_modes,
       max_contract,
       CASE WHEN hd_buy_potential = 'HIGH' THEN 'Premium'
            WHEN hd_buy_potential = 'MEDIUM' THEN 'Midrange'
            ELSE 'Budget' END AS potential_category,
       SUM(total_net_profit) OVER (PARTITION BY hd_income_band_sk) AS income_band_profit_total,
       RANK() OVER (ORDER BY total_avg_quantity DESC) AS avg_quantity_rank
FROM combined
WHERE distinct_ship_modes >= 2
  AND hd_income_band_sk IS NOT NULL
GROUP BY hd_demo_sk, hd_income_band_sk, total_net_profit, total_avg_quantity,
         distinct_ship_modes, air_ship_modes, ground_ship_modes, max_contract, hd_buy_potential
ORDER BY income_band_profit_total DESC, avg_quantity_rank ASC
FETCH FIRST 15 ROWS ONLY
