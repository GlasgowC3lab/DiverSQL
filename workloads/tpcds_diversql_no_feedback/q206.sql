WITH ws AS (
    SELECT
        sm.sm_ship_mode_sk,
        sm.sm_carrier,
        sm.sm_ship_mode_id,
        concat(sm.sm_carrier, '-', regexp_extract(sm.sm_ship_mode_id, '([A-Z]+)')) AS carrier_code,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_url LIKE '%/product/%'
      AND regexp_like(sm.sm_carrier, '^AIR|USPS')
    GROUP BY sm.sm_ship_mode_sk, sm.sm_carrier, sm.sm_ship_mode_id, concat(sm.sm_carrier, '-', regexp_extract(sm.sm_ship_mode_id, '([A-Z]+)'))
),
cr AS (
    SELECT
        sm.sm_ship_mode_sk,
        sm.sm_carrier,
        sm.sm_ship_mode_id,
        concat(sm.sm_carrier, '-', regexp_extract(sm.sm_ship_mode_id, '([A-Z]+)')) AS carrier_code,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
        COUNT(*) AS returns_cnt,
        cc.cc_name
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE regexp_like(cc.cc_name, '^Call')
    GROUP BY sm.sm_ship_mode_sk, sm.sm_carrier, sm.sm_ship_mode_id, concat(sm.sm_carrier, '-', regexp_extract(sm.sm_ship_mode_id, '([A-Z]+)')), cc.cc_name
)
SELECT
    ws.carrier_code,
    ws.sm_carrier,
    ws.sm_ship_mode_id,
    SUM(ws.total_net_paid) AS sum_net_paid,
    SUM(cr.total_return_amount) AS sum_return_amount,
    SUM(ws.sales_cnt) AS sum_sales_cnt,
    SUM(cr.returns_cnt) AS sum_returns_cnt,
    SUBSTR(cr.cc_name, 1, 10) AS short_center_name,
    SUM(ws.total_net_paid - cr.total_return_amount) AS net_profit_estimate
FROM ws
JOIN cr ON ws.sm_ship_mode_sk = cr.sm_ship_mode_sk
WHERE ws.total_net_paid > 0
GROUP BY ws.carrier_code, ws.sm_carrier, ws.sm_ship_mode_id, SUBSTR(cr.cc_name, 1, 10)
HAVING SUM(ws.sales_cnt) > 10
ORDER BY net_profit_estimate DESC
LIMIT 100
