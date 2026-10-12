WITH sampled_sales AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    sm.sm_code,
    ws.ws_net_profit
FROM sampled_sales ws
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE c.c_customer_sk IN (
    SELECT intersected.cust_sk
    FROM (
        SELECT ws1.ws_bill_customer_sk AS cust_sk
        FROM sampled_sales ws1
        JOIN ship_mode sm1
            ON ws1.ws_ship_mode_sk = sm1.sm_ship_mode_sk
        WHERE sm1.sm_code = 'AIR'
          AND ws1.ws_ext_discount_amt > 500

        INTERSECT

        SELECT ws2.ws_ship_customer_sk AS cust_sk
        FROM sampled_sales ws2
        JOIN ship_mode sm2
            ON ws2.ws_ship_mode_sk = sm2.sm_ship_mode_sk
        WHERE sm2.sm_code = 'SEA'
          AND ws2.ws_wholesale_cost < 70
    ) AS intersected
    EXCEPT
    SELECT c3.c_customer_sk
    FROM customer c3
    WHERE c3.c_last_review_date > 2452500
)
  AND ws.ws_net_profit > (
    SELECT avg(ws4.ws_net_profit)
    FROM sampled_sales ws4
)
ORDER BY ws.ws_net_profit DESC
LIMIT 100
