WITH cust_profit AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        SUM(ws.ws_net_paid) AS total_paid,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, c.c_birth_year
)
SELECT
    cp.c_customer_id,
    cp.c_first_name,
    cp.c_last_name,
    cp.c_birth_year,
    cp.total_paid,
    cp.total_profit,
    CASE
        WHEN cp.total_profit >= 5000 THEN 'Platinum'
        WHEN cp.total_profit >= 2000 THEN 'Gold'
        WHEN cp.total_profit >= 500 THEN 'Silver'
        ELSE 'Bronze'
    END AS profit_tier,
    RANK() OVER (ORDER BY cp.total_profit DESC) AS profit_rank,
    LAG(cp.total_profit) OVER (PARTITION BY cp.c_birth_year ORDER BY cp.total_profit) AS prev_profit_same_birthyear
FROM cust_profit cp
ORDER BY cp.total_profit DESC
LIMIT 20
