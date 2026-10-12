WITH distinct_promos AS (
    SELECT DISTINCT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_cost,
        p.p_channel_catalog
    FROM promotion p
    WHERE p.p_channel_catalog = 'N'
      AND p.p_cost BETWEEN 500 AND 2000
),
filtered_sales AS (
    SELECT
        ws.ws_bill_customer_sk,
        ws.ws_promo_sk,
        ws.ws_ext_tax,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_ext_tax > 50
      AND ws.ws_ext_sales_price > 200
      AND ws.ws_ship_hdemo_sk IN (2307, 3114)
),
joined_data AS (
    SELECT
        dp.p_promo_name AS promo_name,
        c.c_customer_id AS customer_id,
        c.c_birth_country AS birth_country,
        fs.ws_net_profit,
        fs.ws_ext_sales_price,
        fs.ws_order_number
    FROM filtered_sales fs
    JOIN customer c
      ON fs.ws_bill_customer_sk = c.c_customer_sk
    JOIN distinct_promos dp
      ON fs.ws_promo_sk = dp.p_promo_sk
    WHERE c.c_birth_country = 'JORDAN'
      AND c.c_birth_year >= 1965
)
SELECT
    promo_name,
    customer_id,
    birth_country,
    total_net_profit,
    avg_sales_price,
    distinct_orders
FROM (
    SELECT
        promo_name,
        customer_id,
        birth_country,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_ext_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws_order_number) AS distinct_orders,
        ROW_NUMBER() OVER (PARTITION BY promo_name ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM joined_data
    GROUP BY promo_name, customer_id, birth_country
) t
WHERE rn <= 5
ORDER BY total_net_profit DESC
LIMIT 100
