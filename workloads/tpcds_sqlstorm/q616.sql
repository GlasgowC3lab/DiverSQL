WITH
customer_addr AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        ca.ca_city,
        ca.ca_country
    FROM customer c
    LEFT JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_agg AS (
    SELECT ss.ss_customer_sk AS customer_sk,
           SUM(ss.ss_net_profit) AS total_profit,
           SUM(ss.ss_quantity) AS total_quantity,
           'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY ss.ss_customer_sk
    UNION ALL
    SELECT cs.cs_bill_customer_sk AS customer_sk,
           SUM(cs.cs_net_profit) AS total_profit,
           SUM(cs.cs_quantity) AS total_quantity,
           'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY cs.cs_bill_customer_sk
    UNION ALL
    SELECT ws.ws_bill_customer_sk AS customer_sk,
           SUM(ws.ws_net_profit) AS total_profit,
           SUM(ws.ws_quantity) AS total_quantity,
           'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY ws.ws_bill_customer_sk
),
total_sales_per_customer AS (
    SELECT
        customer_sk,
        SUM(total_profit) AS total_profit,
        SUM(total_quantity) AS total_quantity,
        COUNT(DISTINCT channel) AS channel_count
    FROM sales_agg
    GROUP BY customer_sk
),
avg_state_profit AS (
    SELECT
        ca.ca_state,
        AVG(ts.total_profit) AS avg_state_profit
    FROM total_sales_per_customer ts
    JOIN customer_addr ca ON ts.customer_sk = ca.c_customer_sk
    WHERE ts.total_profit IS NOT NULL
    GROUP BY ca.ca_state
),
customer_stats AS (
    SELECT
        ca.c_customer_sk,
        ca.c_customer_id,
        ca.c_first_name,
        ca.c_last_name,
        ca.ca_state,
        COALESCE(ca.ca_city, 'UNKNOWN') AS city_name,
        COALESCE(ts.total_profit, 0) AS total_profit,
        COALESCE(ts.total_quantity, 0) AS total_quantity,
        COALESCE(ts.channel_count, 0) AS channel_count,
        CASE
            WHEN COALESCE(ts.total_profit,0) > 5000 THEN 'HIGH'
            WHEN COALESCE(ts.total_profit,0) > 0 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_bucket,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY COALESCE(ts.total_profit,0) DESC) AS rank_state,
        COALESCE(asp.avg_state_profit, 0) AS avg_state_profit,
        (SELECT COUNT(*)
         FROM total_sales_per_customer ts2
         JOIN customer_addr ca2 ON ts2.customer_sk = ca2.c_customer_sk
         WHERE ca2.ca_city = ca.ca_city
           AND COALESCE(ts2.total_profit,0) > COALESCE(ts.total_profit,0)
        ) AS higher_profit_in_city,
        CONCAT(UPPER(ca.c_first_name), ' ', UPPER(ca.c_last_name), ' (', ca.c_customer_id, ')') AS customer_label
    FROM customer_addr ca
    LEFT JOIN total_sales_per_customer ts ON ca.c_customer_sk = ts.customer_sk
    LEFT JOIN avg_state_profit asp ON ca.ca_state = asp.ca_state
)
SELECT
    customer_label,
    city_name,
    total_profit,
    total_quantity,
    profit_bucket,
    rank_state,
    avg_state_profit,
    higher_profit_in_city,
    channel_count
FROM customer_stats
WHERE profit_bucket = 'HIGH'
UNION ALL
SELECT
    customer_label,
    city_name,
    total_profit,
    total_quantity,
    profit_bucket,
    rank_state,
    avg_state_profit,
    higher_profit_in_city,
    channel_count
FROM customer_stats
WHERE profit_bucket = 'LOW'
ORDER BY total_profit DESC, rank_state
