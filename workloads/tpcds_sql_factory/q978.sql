WITH store_agg AS (
    SELECT ss_hdemo_sk AS hd_demo_sk,
           AVG(ss_net_profit) AS avg_store_profit,
           SUM(ss_quantity) AS store_quantity,
           MAX(ss_ext_discount_amt) AS max_store_discount
    FROM store_sales
    GROUP BY ss_hdemo_sk
),
web_agg AS (
    SELECT ws_bill_hdemo_sk AS hd_demo_sk,
           AVG(ws_net_profit) AS avg_web_profit,
           SUM(ws_quantity) AS web_quantity,
           MAX(ws_ext_discount_amt) AS max_web_discount
    FROM web_sales
    GROUP BY ws_bill_hdemo_sk
),
ship_mode_cnt AS (
    SELECT ws_ship_hdemo_sk AS hd_demo_sk,
           COUNT(*) AS total_ship_records
    FROM web_sales ws
    GROUP BY ws_ship_hdemo_sk
),
combined AS (
    SELECT hd.hd_demo_sk,
           hd.hd_income_band_sk,
           COALESCE(sa.avg_store_profit,0) + COALESCE(wa.avg_web_profit,0) AS total_avg_profit,
           COALESCE(sa.store_quantity,0) + COALESCE(wa.web_quantity,0) AS total_quantity,
           GREATEST(COALESCE(sa.max_store_discount,0), COALESCE(wa.max_web_discount,0)) AS max_discount,
           hd.hd_buy_potential,
           COALESCE(sc.total_ship_records,0) AS total_ship_records
    FROM household_demographics hd
    LEFT JOIN store_agg sa ON hd.hd_demo_sk = sa.hd_demo_sk
    LEFT JOIN web_agg wa ON hd.hd_demo_sk = wa.hd_demo_sk
    LEFT JOIN ship_mode_cnt sc ON hd.hd_demo_sk = sc.hd_demo_sk
)
SELECT hd_demo_sk,
       hd_income_band_sk,
       total_avg_profit,
       total_quantity,
       max_discount,
       total_ship_records,
       CASE WHEN hd_buy_potential = 'HIGH' THEN 'Premium'
            WHEN hd_buy_potential = 'MEDIUM' THEN 'Midrange'
            ELSE 'Budget' END AS potential_category,
       CUME_DIST() OVER (ORDER BY total_quantity) AS quantity_cume_dist
FROM combined
WHERE max_discount > 0.05
ORDER BY quantity_cume_dist ASC
FETCH FIRST 25 ROWS ONLY
