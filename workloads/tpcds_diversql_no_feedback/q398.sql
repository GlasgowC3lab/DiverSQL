WITH promo_active AS (
    SELECT p_promo_sk
    FROM promotion
    WHERE p_discount_active = 'Y'
),
store_agg AS (
    SELECT
        'store' AS channel,
        td.t_hour AS hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE p.p_promo_sk IN (SELECT p_promo_sk FROM promo_active)
      AND i.i_category = 'Sports'
    GROUP BY td.t_hour
),
web_agg AS (
    SELECT
        'web' AS channel,
        td.t_hour AS hour,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS transaction_count
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE p.p_promo_sk IN (SELECT p_promo_sk FROM promo_active)
      AND i.i_category = 'Sports'
    GROUP BY td.t_hour
)
SELECT *
FROM store_agg
UNION ALL
SELECT *
FROM web_agg
ORDER BY hour, channel
LIMIT 100
