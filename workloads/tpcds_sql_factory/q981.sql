WITH store_agg AS (
    SELECT ss_hdemo_sk AS hd_demo_sk,
           SUM(ss_net_profit) AS store_net_profit,
           SUM(ss_quantity) AS store_quantity,
           MIN(ss_ext_discount_amt) AS min_store_discount
    FROM store_sales
    WHERE ss_sold_date_sk >= 2450000
    GROUP BY ss_hdemo_sk
),
web_agg AS (
    SELECT ws_bill_hdemo_sk AS hd_demo_sk,
           SUM(ws_net_profit) AS web_net_profit,
           SUM(ws_quantity) AS web_quantity,
           MIN(ws_ext_discount_amt) AS min_web_discount
    FROM web_sales
    WHERE ws_sold_date_sk < 2450000
    GROUP BY ws_bill_hdemo_sk
),
ship_mode_cnt AS (
    SELECT ws_ship_hdemo_sk AS hd_demo_sk,
           COUNT(DISTINCT sm.sm_ship_mode_id) AS distinct_ship_modes
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY ws_ship_hdemo_sk
),
combined AS (
    SELECT hd.hd_demo_sk,
           hd.hd_income_band_sk,
           COALESCE(sa.store_net_profit,0) - COALESCE(wa.web_net_profit,0) AS net_profit_diff,
           COALESCE(sa.store_quantity,0) + COALESCE(wa.web_quantity,0) AS total_quantity,
           LEAST(COALESCE(sa.min_store_discount,0), COALESCE(wa.min_web_discount,0)) AS min_discount,
           hd.hd_buy_potential,
           COALESCE(sc.distinct_ship_modes,0) AS distinct_ship_modes
    FROM household_demographics hd
    LEFT JOIN store_agg sa ON hd.hd_demo_sk = sa.hd_demo_sk
    LEFT JOIN web_agg wa ON hd.hd_demo_sk = wa.hd_demo_sk
    LEFT JOIN ship_mode_cnt sc ON hd.hd_demo_sk = sc.hd_demo_sk
)
SELECT hd_demo_sk,
       hd_income_band_sk,
       net_profit_diff,
       total_quantity,
       min_discount,
       distinct_ship_modes,
       CASE WHEN hd_buy_potential = 'HIGH' THEN 'Premium'
            WHEN hd_buy_potential = 'MEDIUM' THEN 'Midrange'
            ELSE 'Budget' END AS potential_category,
       ROW_NUMBER() OVER (ORDER BY net_profit_diff DESC) AS profit_rank
FROM combined
WHERE total_quantity > 1000
ORDER BY profit_rank
LIMIT 20
