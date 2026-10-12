WITH store_agg AS (
    SELECT ss_hdemo_sk AS hd_demo_sk,
           SUM(ss_net_profit) AS store_net_profit,
           COUNT(*) AS store_transactions,
           MAX(ss_ext_discount_amt) AS max_store_discount
    FROM store_sales
    WHERE ss_quantity > 0
    GROUP BY ss_hdemo_sk
),
web_agg AS (
    SELECT ws_bill_hdemo_sk AS hd_demo_sk,
           SUM(ws_net_profit) AS web_net_profit,
           COUNT(*) AS web_transactions,
           MAX(ws_ext_discount_amt) AS max_web_discount
    FROM web_sales
    WHERE ws_quantity > 0
    GROUP BY ws_bill_hdemo_sk
),
ship_mode_cnt AS (
    SELECT ws_ship_hdemo_sk AS hd_demo_sk,
           COUNT(DISTINCT sm.sm_carrier) AS distinct_carriers
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY ws_ship_hdemo_sk
),
combined AS (
    SELECT hd.hd_demo_sk,
           hd.hd_income_band_sk,
           COALESCE(sa.store_net_profit,0) + COALESCE(wa.web_net_profit,0) AS total_net_profit,
           COALESCE(sa.store_transactions,0) + COALESCE(wa.web_transactions,0) AS total_transactions,
           GREATEST(COALESCE(sa.max_store_discount,0), COALESCE(wa.max_web_discount,0)) AS max_discount,
           hd.hd_buy_potential,
           COALESCE(sc.distinct_carriers,0) AS distinct_carriers
    FROM household_demographics hd
    LEFT JOIN store_agg sa ON hd.hd_demo_sk = sa.hd_demo_sk
    LEFT JOIN web_agg wa ON hd.hd_demo_sk = wa.hd_demo_sk
    LEFT JOIN ship_mode_cnt sc ON hd.hd_demo_sk = sc.hd_demo_sk
)
SELECT hd_demo_sk,
       hd_income_band_sk,
       total_net_profit,
       total_transactions,
       max_discount,
       distinct_carriers,
       CASE WHEN hd_buy_potential = 'HIGH' THEN 'Premium'
            WHEN hd_buy_potential = 'MEDIUM' THEN 'Midrange'
            ELSE 'Budget' END AS potential_category,
       NTILE(5) OVER (ORDER BY total_transactions DESC) AS transaction_quintile,
       RANK() OVER (PARTITION BY hd_buy_potential ORDER BY max_discount DESC) AS discount_rank_within_potential
FROM combined
WHERE total_net_profit > 0
ORDER BY transaction_quintile, discount_rank_within_potential
LIMIT 15
