WITH store_agg AS (
    SELECT ss_hdemo_sk AS hd_demo_sk,
           SUM(ss_net_profit) AS store_net_profit,
           MAX(ss_quantity) AS max_store_qty
    FROM store_sales
    GROUP BY ss_hdemo_sk
),
web_agg AS (
    SELECT ws_bill_hdemo_sk AS hd_demo_sk,
           SUM(ws_net_profit) AS web_net_profit,
           MAX(ws_quantity) AS max_web_qty
    FROM web_sales
    GROUP BY ws_bill_hdemo_sk
),
ship_mode_cnt AS (
    SELECT ws_ship_hdemo_sk AS hd_demo_sk,
           COUNT(DISTINCT sm.sm_ship_mode_sk) AS distinct_ship_modes,
           SUM(CASE WHEN sm.sm_type = 'AIR' THEN 1 ELSE 0 END) AS air_ship_modes,
           SUM(CASE WHEN sm.sm_type = 'GROUND' THEN 1 ELSE 0 END) AS ground_ship_modes
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_contract = 'STANDARD'
    GROUP BY ws_ship_hdemo_sk
),
combined AS (
    SELECT hd.hd_demo_sk,
           hd.hd_income_band_sk,
           COALESCE(sa.store_net_profit,0) + COALESCE(wa.web_net_profit,0) AS total_net_profit,
           GREATEST(COALESCE(sa.max_store_qty,0), COALESCE(wa.max_web_qty,0)) AS max_quantity,
           hd.hd_buy_potential,
           COALESCE(sc.distinct_ship_modes,0) AS distinct_ship_modes,
           COALESCE(sc.air_ship_modes,0) AS air_ship_modes,
           COALESCE(sc.ground_ship_modes,0) AS ground_ship_modes
    FROM household_demographics hd
    LEFT JOIN store_agg sa ON hd.hd_demo_sk = sa.hd_demo_sk
    LEFT JOIN web_agg wa ON hd.hd_demo_sk = wa.hd_demo_sk
    LEFT JOIN ship_mode_cnt sc ON hd.hd_demo_sk = sc.hd_demo_sk
)
SELECT hd_demo_sk,
       hd_income_band_sk,
       total_net_profit,
       max_quantity,
       distinct_ship_modes,
       air_ship_modes,
       ground_ship_modes,
       CASE WHEN hd_buy_potential = 'HIGH' THEN 'Premium'
            WHEN hd_buy_potential = 'MEDIUM' THEN 'Midrange'
            ELSE 'Budget' END AS potential_category,
       SUM(total_net_profit) OVER (PARTITION BY hd_income_band_sk) AS income_band_total_profit,
       DENSE_RANK() OVER (ORDER BY max_quantity DESC) AS quantity_dense_rank
FROM combined
WHERE distinct_ship_modes >= 1
  AND max_quantity > 0
GROUP BY hd_demo_sk, hd_income_band_sk, total_net_profit, max_quantity,
         distinct_ship_modes, air_ship_modes, ground_ship_modes, hd_buy_potential
ORDER BY income_band_total_profit DESC, quantity_dense_rank ASC
FETCH FIRST 25 ROWS ONLY
