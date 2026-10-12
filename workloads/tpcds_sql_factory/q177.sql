WITH store_agg AS (
    SELECT ss_hdemo_sk AS hd_demo_sk,
           SUM(ss_net_profit) AS store_net_profit,
           COUNT(*) AS store_txn_cnt
    FROM store_sales
    WHERE ss_sold_date_sk >= 2450000
    GROUP BY ss_hdemo_sk
),
web_agg AS (
    SELECT ws_bill_hdemo_sk AS hd_demo_sk,
           SUM(ws_net_profit) AS web_net_profit,
           COUNT(*) AS web_txn_cnt
    FROM web_sales
    WHERE ws_sold_date_sk >= 2450000
    GROUP BY ws_bill_hdemo_sk
),
ship_mode_cnt AS (
    SELECT ws_ship_hdemo_sk AS hd_demo_sk,
           COUNT(DISTINCT sm.sm_ship_mode_sk) AS distinct_ship_modes,
           COUNT(*) FILTER (WHERE sm.sm_type = 'AIR') AS air_ship_modes,
           COUNT(*) FILTER (WHERE sm.sm_type = 'GROUND') AS ground_ship_modes
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY ws_ship_hdemo_sk
),
combined AS (
    SELECT hd.hd_demo_sk,
           hd.hd_income_band_sk,
           COALESCE(sa.store_net_profit,0) + COALESCE(wa.web_net_profit,0) AS total_net_profit,
           COALESCE(sa.store_txn_cnt,0) + COALESCE(wa.web_txn_cnt,0) AS total_txn_cnt,
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
       total_txn_cnt,
       distinct_ship_modes,
       air_ship_modes,
       ground_ship_modes,
       CASE WHEN hd_buy_potential = 'HIGH' THEN 'Premium'
            WHEN hd_buy_potential = 'MEDIUM' THEN 'Midrange'
            ELSE 'Budget' END AS potential_category,
       AVG(total_net_profit) OVER (PARTITION BY hd_income_band_sk) AS income_band_profit_avg,
       ROW_NUMBER() OVER (PARTITION BY hd_income_band_sk ORDER BY total_txn_cnt DESC) AS txn_rank
FROM combined
WHERE total_txn_cnt > 10
ORDER BY income_band_profit_avg DESC, txn_rank ASC
FETCH FIRST 25 ROWS ONLY
