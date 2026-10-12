WITH max_profit AS (
    SELECT max(ws_net_profit) AS max_profit
    FROM web_sales
),
web_data AS (
    SELECT DISTINCT
        c.c_customer_id,
        d.d_date,
        ws.ws_net_paid AS amount,
        'web' AS source
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_net_profit = (SELECT max_profit FROM max_profit)
      AND p.p_channel_radio = 'N'
),
store_data AS (
    SELECT DISTINCT
        c.c_customer_id,
        d.d_date,
        sr.sr_net_loss AS amount,
        'store' AS source
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_net_loss > 0
),
union_data AS (
    SELECT c_customer_id, d_date, amount, source FROM web_data
    UNION ALL
    SELECT c_customer_id, d_date, amount, source FROM store_data
),
cross_data AS (
    SELECT u.c_customer_id,
           u.d_date,
           u.amount,
           u.source,
           sm.sm_type AS ship_mode_type
    FROM union_data u
    CROSS JOIN (
        SELECT sm_type FROM ship_mode WHERE sm_type IN ('AIR', 'RAIL') LIMIT 2
    ) sm
)
SELECT DISTINCT
    c_customer_id,
    d_date,
    amount,
    source,
    ship_mode_type
FROM cross_data
ORDER BY amount DESC
LIMIT 100
