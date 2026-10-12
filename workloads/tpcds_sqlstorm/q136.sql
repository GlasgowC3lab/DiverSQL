WITH store_sales_agg AS (
    SELECT ss_customer_sk AS customer_sk, SUM(ss_net_profit) AS profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 1999
    GROUP BY ss_customer_sk
),
web_sales_agg AS (
    SELECT ws_bill_customer_sk AS customer_sk, SUM(ws_net_profit) AS profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 1999
    GROUP BY ws_bill_customer_sk
),
catalog_sales_agg AS (
    SELECT cs_bill_customer_sk AS customer_sk, SUM(cs_net_profit) AS profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 1999
    GROUP BY cs_bill_customer_sk
),
combined_sales AS (
    SELECT customer_sk, profit FROM store_sales_agg
    UNION ALL
    SELECT customer_sk, profit FROM web_sales_agg
    UNION ALL
    SELECT customer_sk, profit FROM catalog_sales_agg
)
SELECT c.c_customer_id, SUM(cs.profit) AS total_profit
FROM combined_sales cs
JOIN customer c ON cs.customer_sk = c.c_customer_sk
GROUP BY c.c_customer_id
ORDER BY total_profit DESC
LIMIT 100
