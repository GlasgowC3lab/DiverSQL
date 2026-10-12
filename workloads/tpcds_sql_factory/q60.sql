WITH store_agg AS (
    SELECT ss_hdemo_sk AS hd_demo_sk,
           SUM(ss_net_profit) AS store_net_profit,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_hdemo_sk
),
web_agg AS (
    SELECT ws_bill_hdemo_sk AS hd_demo_sk,
           SUM(ws_net_profit) AS web_net_profit,
           SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_bill_hdemo_sk
),
ship_mode_cnt AS (
    SELECT ws_ship_hdemo_sk AS hd_demo_sk,
           COUNT(DISTINCT sm.sm_ship_mode_sk) AS distinct_ship_modes
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY ws_ship_hdemo_sk
),
combined AS (
    SELECT hd.hd_demo_sk,
           hd.hd_income_band_sk,
           COALESCE(sa.store_net_profit,0) + COALESCE(wa.web_net_profit,0) AS total_net_profit,
           COALESCE(sa.store_quantity,0) + COALESCE(wa.web_quantity,0) AS total_quantity,
           hd.hd_buy_potential,
           COALESCE(sc.distinct_ship_modes,0) AS distinct_ship_modes,
           CASE WHEN hd.hd_income_band_sk BETWEEN 1 AND 3 THEN 'Low Income'
                WHEN hd.hd_income_band_sk BETWEEN 4 AND 6 THEN 'Middle Income'
                ELSE 'High Income' END AS income_category
    FROM household_demographics hd
    LEFT JOIN store_agg sa ON hd.hd_demo_sk = sa.hd_demo_sk
    LEFT JOIN web_agg wa ON hd.hd_demo_sk = wa.hd_demo_sk
    LEFT JOIN ship_mode_cnt sc ON hd.hd_demo_sk = sc.hd_demo_sk
)
SELECT hd_demo_sk,
       income_category,
       total_net_profit,
       total_quantity,
       distinct_ship_modes,
       CASE WHEN hd_buy_potential = 'HIGH' THEN 'Premium'
            WHEN hd_buy_potential = 'MEDIUM' THEN 'Midrange'
            ELSE 'Budget' END AS potential_category,
       RANK() OVER (PARTITION BY income_category ORDER BY total_quantity DESC) AS qty_rank_by_income
FROM combined
WHERE total_net_profit > 0
ORDER BY qty_rank_by_income ASC,
         total_net_profit DESC
FETCH FIRST 25 ROWS ONLY
