WITH promo_orders AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_radio = 'Y'
      AND p.p_end_date_sk > 2450000
),
promo_orders_tv AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_tv = 'Y'
      AND p.p_end_date_sk > 2450000
),
order_exceptions AS (
    SELECT ws_order_number
    FROM promo_orders
    EXCEPT
    SELECT ws_order_number
    FROM promo_orders_tv
)
SELECT
    p.p_promo_name,
    ws.ws_order_number,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    CASE WHEN ws.ws_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
    COUNT(DISTINCT ws.ws_bill_customer_sk) OVER (PARTITION BY p.p_promo_name) AS distinct_customers_in_promo,
    SUM(DISTINCT ws.ws_ext_sales_price) OVER (PARTITION BY p.p_promo_name) AS distinct_sales_sum,
    ROW_NUMBER() OVER (PARTITION BY p.p_promo_name ORDER BY ws.ws_net_profit DESC) AS profit_rank,
    (SELECT SUM(ws2.ws_quantity) FROM web_sales ws2 WHERE ws2.ws_item_sk = ws.ws_item_sk) AS total_quantity_for_item,
    channel_word
FROM web_sales ws
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN order_exceptions oe ON ws.ws_order_number = oe.ws_order_number
CROSS JOIN UNNEST(split(p.p_channel_details, ',')) AS t(channel_word)
WHERE
    ws.ws_ship_customer_sk IN (253825, 9221248, 11996091)
    AND ws.ws_bill_hdemo_sk BETWEEN 200 AND 4000
    AND ws.ws_quantity > 0
    AND ws.ws_net_profit IS NOT NULL
    AND p.p_end_date_sk >= 2450169
    AND p.p_channel_radio = 'N'
    AND p.p_promo_name IS NOT NULL
ORDER BY ws.ws_net_profit DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
