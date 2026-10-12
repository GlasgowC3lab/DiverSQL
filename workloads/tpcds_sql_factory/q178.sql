WITH store_agg AS (
    SELECT ss_hdemo_sk AS hd_demo_sk,
           SUM(ss_net_profit) AS store_net_profit,
           SUM(ss_ext_discount_amt) AS store_discount_total
    FROM store_sales
    GROUP BY ss_hdemo_sk
),
web_agg AS (
    SELECT ws_bill_hdemo_sk AS hd_demo_sk,
           SUM(ws_net_profit) AS web_net_profit,
           SUM(ws_ext_discount_amt) AS web_discount_total
    FROM web_sales
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
           COALESCE(sa.store_discount_total,0) + COALESCE(wa.web_discount_total,0) AS total_discount,
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
       total_discount,
       distinct_ship_modes,
       air_ship_modes,
       ground_ship_modes,
       CASE WHEN total_discount > 0 THEN 'Discounted' ELSE 'Full Price' END AS price_category,
       SUM(total_net_profit) OVER (PARTITION BY hd_income_band_sk) AS income_band_profit_total,
       DENSE_RANK() OVER (ORDER BY total_discount DESC) AS discount_rank
FROM combined
WHERE total_net_profit BETWEEN -5000 AND 5000
ORDER BY discount_rank ASC, income_band_profit_total DESC
LIMIT 30
