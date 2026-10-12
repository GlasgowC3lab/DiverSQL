WITH store_agg AS (
    SELECT ss_hdemo_sk AS hd_demo_sk,
           SUM(ss_net_profit) AS store_net_profit,
           COUNT(DISTINCT ss_item_sk) AS store_unique_items
    FROM store_sales
    WHERE ss_net_paid_inc_tax > 0
    GROUP BY ss_hdemo_sk
),
web_agg AS (
    SELECT ws_bill_hdemo_sk AS hd_demo_sk,
           SUM(ws_net_profit) AS web_net_profit,
           COUNT(DISTINCT ws_item_sk) AS web_unique_items
    FROM web_sales
    WHERE ws_net_paid_inc_tax > 0
    GROUP BY ws_bill_hdemo_sk
),
ship_mode_cnt AS (
    SELECT ws_ship_hdemo_sk AS hd_demo_sk,
           COUNT(DISTINCT sm.sm_ship_mode_sk) AS distinct_ship_modes,
           COUNT(*) FILTER (WHERE sm.sm_type = 'AIR') AS air_ship_modes,
           COUNT(*) FILTER (WHERE sm.sm_type = 'GROUND') AS ground_ship_modes,
           MIN(sm.sm_type) AS first_ship_type
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY ws_ship_hdemo_sk
),
combined AS (
    SELECT hd.hd_demo_sk,
           hd.hd_income_band_sk,
           COALESCE(sa.store_net_profit,0) + COALESCE(wa.web_net_profit,0) AS total_net_profit,
           COALESCE(sa.store_unique_items,0) + COALESCE(wa.web_unique_items,0) AS total_unique_items,
           hd.hd_buy_potential,
           COALESCE(sc.distinct_ship_modes,0) AS distinct_ship_modes,
           COALESCE(sc.air_ship_modes,0) AS air_ship_modes,
           COALESCE(sc.ground_ship_modes,0) AS ground_ship_modes,
           sc.first_ship_type
    FROM household_demographics hd
    LEFT JOIN store_agg sa ON hd.hd_demo_sk = sa.hd_demo_sk
    LEFT JOIN web_agg wa ON hd.hd_demo_sk = wa.hd_demo_sk
    LEFT JOIN ship_mode_cnt sc ON hd.hd_demo_sk = sc.hd_demo_sk
)
SELECT hd_demo_sk,
       hd_income_band_sk,
       total_net_profit,
       total_unique_items,
       distinct_ship_modes,
       air_ship_modes,
       ground_ship_modes,
       first_ship_type,
       CASE WHEN hd_buy_potential = 'HIGH' THEN 'Premium'
            WHEN hd_buy_potential = 'MEDIUM' THEN 'Midrange'
            ELSE 'Budget' END AS potential_category,
       SUM(total_net_profit) OVER (PARTITION BY hd_income_band_sk) AS income_band_profit_sum,
       ROW_NUMBER() OVER (PARTITION BY hd_income_band_sk ORDER BY total_unique_items DESC) AS unique_item_rank
FROM combined
WHERE total_unique_items > 2
  AND distinct_ship_modes > 0
ORDER BY income_band_profit_sum DESC, unique_item_rank ASC
FETCH FIRST 30 ROWS ONLY
