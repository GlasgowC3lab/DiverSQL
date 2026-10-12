WITH union_sales AS (
    -- Store sales side
    SELECT
        CAST('store' AS varchar) AS sales_channel,
        c.c_customer_id AS customer_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_event = 'N'
      AND ss.ss_net_profit > (SELECT AVG(cr_return_amount) FROM catalog_returns)
    GROUP BY c.c_customer_id

    UNION ALL

    -- Web sales side
    SELECT
        CAST('web' AS varchar) AS sales_channel,
        c.c_customer_id AS customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE p.p_channel_event = 'N'
      AND sm.sm_contract = 'I3uCelXtjP'
      AND ws.ws_net_profit > (SELECT AVG(cr_return_amount) FROM catalog_returns)
    GROUP BY c.c_customer_id
)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS row_num,
    sales_channel,
    customer_id,
    total_quantity,
    total_net_paid,
    total_net_profit
FROM union_sales
ORDER BY total_net_profit DESC
LIMIT 100
