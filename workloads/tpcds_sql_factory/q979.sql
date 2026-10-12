WITH store_agg AS (
    SELECT ss_hdemo_sk AS hd_demo_sk,
           SUM(ss_net_profit) AS store_net_profit,
           SUM(ss_quantity) AS store_quantity,
           AVG(ss_ext_discount_amt) AS avg_store_discount
    FROM store_sales
    GROUP BY ss_hdemo_sk
),
web_agg AS (
    SELECT ws_bill_hdemo_sk AS hd_demo_sk,
           SUM(ws_net_profit) AS web_net_profit,
           SUM(ws_quantity) AS web_quantity,
           AVG(ws_ext_discount_amt) AS avg_web_discount
    FROM web_sales
    GROUP BY ws_bill_hdemo_sk
),
ship_mode_cnt AS (
    SELECT ws_ship_hdemo_sk AS hd_demo_sk,
           COUNT(DISTINCT sm.sm_ship_mode_id) AS distinct_ship_mode_ids
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY ws_ship_hdemo_sk
),
combined AS (
    SELECT hd.hd_demo_sk,
           hd.hd_income_band_sk,
           COALESCE(sa.store_net_profit,0) + COALESCE(wa.web_net_profit,0) AS total_net_profit,
           COALESCE(sa.store_quantity,0) + COALESCE(wa.web_quantity,0) AS total_quantity,
           (COALESCE(sa.avg_store_discount,0) + COALESCE(wa.avg_web_discount,0)) / 2 AS avg_discount,
           hd.hd_buy_potential,
           COALESCE(sc.distinct_ship_mode_ids,0) AS distinct_ship_mode_ids
    FROM household_demographics hd
    LEFT JOIN store_agg sa ON hd.hd_demo_sk = sa.hd_demo_sk
    LEFT JOIN web_agg wa ON hd.hd_demo_sk = wa.hd_demo_sk
    LEFT JOIN ship_mode_cnt sc ON hd.hd_demo_sk = sc.hd_demo_sk
)
SELECT hd_demo_sk,
       hd_income_band_sk,
       total_net_profit,
       total_quantity,
       avg_discount,
       distinct_ship_mode_ids,
       CASE WHEN hd_buy_potential = 'HIGH' THEN 'Premium'
            WHEN hd_buy_potential = 'MEDIUM' THEN 'Midrange'
            ELSE 'Budget' END AS potential_category,
       PERCENT_RANK() OVER (PARTITION BY hd_buy_potential ORDER BY avg_discount DESC) AS discount_percentile_within_potential,
       SUM(total_net_profit) OVER (PARTITION BY hd_income_band_sk) AS band_net_profit_total
FROM combined
WHERE avg_discount BETWEEN 0.01 AND 0.20
ORDER BY discount_percentile_within_potential DESC, band_net_profit_total ASC
FETCH FIRST 40 ROWS ONLY
