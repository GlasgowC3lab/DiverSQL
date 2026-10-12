WITH web_agg AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_ship_mode_sk,
        SUM(ws_net_paid_inc_tax) AS web_net_paid_inc_tax,
        SUM(ws_net_profit) AS web_net_profit,
        SUM(ws_quantity) AS web_quantity
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2450100
      AND ws_ship_mode_sk IN (1, 2, 3)
    GROUP BY ws_sold_date_sk, ws_item_sk, ws_ship_mode_sk
),
store_agg AS (
    SELECT
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_net_paid_inc_tax) AS store_net_paid_inc_tax,
        SUM(ss_net_profit) AS store_net_profit,
        SUM(ss_quantity) AS store_quantity
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY ss_sold_date_sk, ss_item_sk
)
SELECT
    sm.sm_type,
    sm.sm_carrier,
    wa.ws_sold_date_sk AS sold_date_sk,
    wa.ws_item_sk AS item_sk,
    wa.web_net_paid_inc_tax,
    sa.store_net_paid_inc_tax,
    wa.web_net_profit,
    sa.store_net_profit,
    (wa.web_net_paid_inc_tax - sa.store_net_paid_inc_tax) AS net_paid_diff,
    (wa.web_net_profit - sa.store_net_profit) AS net_profit_diff,
    CASE
        WHEN (wa.web_net_profit - sa.store_net_profit) > 0 THEN 'WEB_BETTER'
        WHEN (wa.web_net_profit - sa.store_net_profit) < 0 THEN 'STORE_BETTER'
        ELSE 'EQUAL'
    END AS profit_comparison
FROM web_agg wa
JOIN store_agg sa
    ON wa.ws_sold_date_sk = sa.ss_sold_date_sk
   AND wa.ws_item_sk = sa.ss_item_sk
JOIN ship_mode sm
    ON wa.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE wa.web_quantity > 0
  AND sm.sm_type = 'EXPRESS'
ORDER BY net_profit_diff DESC
LIMIT 100
