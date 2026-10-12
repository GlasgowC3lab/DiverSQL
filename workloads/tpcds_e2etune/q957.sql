WITH catalog_agg AS (
    SELECT
        ca.ca_state,
        p.p_channel_email,
        t.t_hour,
        COUNT(*) AS catalog_orders,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(cs.cs_sales_price) AS catalog_sales_total,
        AVG(cs.cs_sales_price) AS avg_catalog_price
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE ca.ca_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
      AND p.p_channel_email = 'Y'
    GROUP BY ca.ca_state, p.p_channel_email, t.t_hour
),
store_agg AS (
    SELECT
        ca.ca_state,
        p.p_channel_email,
        t.t_hour,
        COUNT(*) AS store_orders,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ss.ss_sales_price) AS store_sales_total,
        AVG(ss.ss_sales_price) AS avg_store_price
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ca.ca_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
      AND p.p_channel_email = 'Y'
    GROUP BY ca.ca_state, p.p_channel_email, t.t_hour
)
SELECT
    COALESCE(ca.ca_state, sa.ca_state) AS state,
    COALESCE(ca.p_channel_email, sa.p_channel_email) AS channel_email,
    COALESCE(ca.t_hour, sa.t_hour) AS hour,
    COALESCE(catalog_orders, 0) AS catalog_orders,
    COALESCE(store_orders, 0) AS store_orders,
    COALESCE(catalog_profit, 0) AS catalog_profit,
    COALESCE(store_profit, 0) AS store_profit,
    COALESCE(catalog_profit, 0) + COALESCE(store_profit, 0) AS total_profit,
    COALESCE(avg_catalog_price, 0) AS avg_catalog_price,
    COALESCE(avg_store_price, 0) AS avg_store_price
FROM catalog_agg ca
FULL OUTER JOIN store_agg sa
    ON ca.ca_state = sa.ca_state
   AND ca.p_channel_email = sa.p_channel_email
   AND ca.t_hour = sa.t_hour
WHERE COALESCE(catalog_profit, 0) + COALESCE(store_profit, 0) > 10000
ORDER BY total_profit DESC
LIMIT 20
