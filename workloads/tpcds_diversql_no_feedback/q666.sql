WITH max_return AS (
       SELECT MAX(wr_return_amt) AS max_amt
       FROM web_returns
       WHERE wr_returned_time_sk = 30553
   ),
   refunded AS (
       SELECT
           c.c_customer_id AS customer_id,
           ca.ca_state AS state,
           SUM(wr.wr_return_amt) AS total_return,
           ROW_NUMBER() OVER (ORDER BY SUM(wr.wr_return_amt) DESC) AS rn
       FROM web_returns wr
       JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
       JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
       JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
       WHERE t.t_meal_time = 'lunch'
         AND wr.wr_return_amt > (SELECT max_amt FROM max_return)
       GROUP BY c.c_customer_id, ca.ca_state
   ),
   returning AS (
       SELECT
           c.c_customer_id AS customer_id,
           ca.ca_state AS state,
           SUM(wr.wr_return_amt) AS total_return,
           ROW_NUMBER() OVER (ORDER BY SUM(wr.wr_return_amt) DESC) AS rn
       FROM web_returns wr
       JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
       JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
       JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
       WHERE t.t_meal_time = 'dinner'
         AND wr.wr_return_amt > (SELECT max_amt FROM max_return)
       GROUP BY c.c_customer_id, ca.ca_state
   )
SELECT
    customer_id,
    state,
    total_return,
    rn
FROM refunded
UNION ALL
SELECT
    customer_id,
    state,
    total_return,
    rn
FROM returning
ORDER BY total_return DESC
LIMIT 100
