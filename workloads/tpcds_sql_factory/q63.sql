WITH store_agg AS (
    SELECT ss_hdemo_sk AS hd_demo_sk,
           SUM(ss_net_profit) AS store_net_profit,
           SUM(ss_quantity) AS store_quantity,
           AVG(ss_sales_price) AS store_avg_price
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY ss_hdemo_sk
),
web_agg AS (
    SELECT ws_bill_hdemo_sk AS hd_demo_sk,
           SUM(ws_net_profit) AS web_net_profit,
           SUM(ws_quantity) AS web_quantity,
           AVG(ws_sales_price) AS web_avg_price
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY ws_bill_hdemo_sk
),
ship_mode_cnt AS (
    SELECT ws_ship_hdemo_sk AS hd_demo_sk,
           COUNT(DISTINCT sm.sm_ship_mode_sk) AS distinct_ship_modes,
           COUNT(*) AS total_shipments
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY ws_ship_hdemo_sk
),
combined AS (
    SELECT hd.hd_demo_sk,
           hd.hd_income_band_sk,
           COALESCE(sa.store_net_profit,0) + COALESCE(wa.web_net_profit,0) AS total_net_profit,
           COALESCE(sa.store_quantity,0) + COALESCE(wa.web_quantity,0) AS total_quantity,
           COALESCE(sa.store_avg_price,0) * 0.6 + COALESCE(wa.web_avg_price,0) * 0.4 AS blended_avg_price,
           hd.hd_buy_potential,
           COALESCE(sc.distinct_ship_modes,0) AS distinct_ship_modes,
           COALESCE(sc.total_shipments,0) AS total_shipments
    FROM household_demographics hd
    LEFT JOIN store_agg sa ON hd.hd_demo_sk = sa.hd_demo_sk
    LEFT JOIN web_agg wa ON hd.hd_demo_sk = wa.hd_demo_sk
    LEFT JOIN ship_mode_cnt sc ON hd.hd_demo_sk = sc.hd_demo_sk
)
SELECT hd_demo_sk,
       hd_income_band_sk,
       total_net_profit,
       total_quantity,
       blended_avg_price,
       distinct_ship_modes,
       total_shipments,
       CASE WHEN hd_buy_potential = 'HIGH' THEN 'Premium'
            WHEN hd_buy_potential = 'MEDIUM' THEN 'Midrange'
            ELSE 'Budget' END AS potential_category,
       ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM combined
WHERE total_quantity > 1000
ORDER BY profit_rank
LIMIT 15
