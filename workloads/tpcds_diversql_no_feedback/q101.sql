WITH agg_sales AS (
    SELECT
        s.s_store_id            AS store_id,
        s.s_store_name          AS store_name,
        p.p_promo_id            AS promo_id,
        p.p_channel_press      AS channel_press,
        SUM(ss.ss_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0) AS store_promo_profit,
        COUNT(ss.ss_ticket_number)                                 AS sales_cnt,
        COUNT(wr.wr_return_quantity)                               AS return_cnt
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returning_customer_sk = c.c_customer_sk
        AND wr.wr_returning_addr_sk = ca.ca_address_sk
    WHERE p.p_channel_press = 'N'
      AND p.p_discount_active = 'N'
      AND s.s_state = 'CA'
      AND ss.ss_sold_time_sk IN (45986, 36794)
      AND c.c_birth_country = 'USA'
      AND ca.ca_city = 'Chicago'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        p.p_promo_id,
        p.p_channel_press
)
SELECT
    store_id,
    store_name,
    promo_id,
    channel_press,
    store_promo_profit,
    sales_cnt,
    return_cnt,
    AVG(store_promo_profit) OVER (PARTITION BY channel_press) AS avg_profit_by_channel,
    LAG(store_promo_profit) OVER (PARTITION BY channel_press ORDER BY store_promo_profit DESC) AS lag_profit,
    CASE
        WHEN store_promo_profit > (SELECT MAX(p_cost) FROM promotion WHERE p_discount_active = 'N')
        THEN 'HIGH'
        ELSE 'NORMAL'
    END AS profit_level
FROM agg_sales
WHERE store_promo_profit > 0
ORDER BY store_promo_profit DESC
LIMIT 100
