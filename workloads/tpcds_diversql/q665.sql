WITH web_sales_2020 AS (
    SELECT c.c_customer_id,
           SUM(ws.ws_net_paid) AS total_spent
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2020
    GROUP BY c.c_customer_id
),
web_returns_2020 AS (
    SELECT DISTINCT c.c_customer_id
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2020
),
store_returns_2020 AS (
    SELECT DISTINCT c.c_customer_id
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2020
),
intersect_customers AS (
    SELECT c_customer_id FROM web_sales_2020
    INTERSECT
    SELECT c_customer_id FROM web_returns_2020
),
final_customers AS (
    SELECT c_customer_id FROM intersect_customers
    EXCEPT
    SELECT c_customer_id FROM store_returns_2020
)
SELECT ws.c_customer_id,
       ws.total_spent
FROM web_sales_2020 ws
JOIN final_customers fc ON ws.c_customer_id = fc.c_customer_id
ORDER BY ws.total_spent DESC
OFFSET 0 ROWS
FETCH FIRST 100 ROWS ONLY
