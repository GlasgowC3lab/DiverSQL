WITH catalog_agg AS (
    SELECT
        cs_bill_customer_sk AS customer_sk,
        SUM(cs_net_paid_inc_tax) AS catalog_net_paid,
        SUM(cs_net_profit) AS catalog_net_profit,
        COUNT(*) AS catalog_orders
    FROM catalog_sales
    GROUP BY cs_bill_customer_sk
),
web_agg AS (
    SELECT
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid_inc_tax) AS web_net_paid,
        SUM(ws_net_profit) AS web_net_profit,
        COUNT(*) AS web_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_month,
        ca.ca_state,
        COALESCE(ca_agg.catalog_net_paid, 0) + COALESCE(wa_agg.web_net_paid, 0) AS total_net_paid,
        COALESCE(ca_agg.catalog_net_profit, 0) + COALESCE(wa_agg.web_net_profit, 0) AS total_net_profit,
        COALESCE(ca_agg.catalog_orders, 0) + COALESCE(wa_agg.web_orders, 0) AS total_orders
    FROM customer c
    LEFT JOIN catalog_agg ca_agg ON c.c_customer_sk = ca_agg.customer_sk
    LEFT JOIN web_agg wa_agg ON c.c_customer_sk = wa_agg.customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.ca_state,
    cs.total_net_paid,
    cs.total_net_profit,
    cs.total_orders,
    CASE WHEN cs.total_net_paid > 5000 THEN 'VIP' ELSE 'Regular' END AS customer_tier,
    RANK() OVER (PARTITION BY cs.ca_state ORDER BY cs.total_net_paid DESC) AS state_rank,
    DENSE_RANK() OVER (ORDER BY cs.total_net_paid DESC) AS global_rank
FROM customer_sales cs
WHERE cs.total_orders > 0
ORDER BY cs.total_net_paid DESC
LIMIT 20
