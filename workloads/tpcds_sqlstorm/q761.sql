WITH sales AS (
    SELECT ss.ss_customer_sk AS cust_sk, ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    UNION ALL
    SELECT ws.ws_bill_customer_sk AS cust_sk, ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
),
cust_sales AS (
    SELECT cust_sk, SUM(net_profit) AS total_net_profit
    FROM sales
    GROUP BY cust_sk
    HAVING SUM(net_profit) > 0
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cs.total_net_profit,
    RANK() OVER (ORDER BY cs.total_net_profit DESC) AS profit_rank
FROM cust_sales cs
JOIN customer c ON cs.cust_sk = c.c_customer_sk
ORDER BY cs.total_net_profit DESC
LIMIT 10
