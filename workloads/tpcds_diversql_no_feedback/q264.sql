WITH intersect_customers AS (
    SELECT cr_returning_customer_sk AS customer_sk
    FROM catalog_returns
    WHERE cr_return_amount > 2000
    INTERSECT
    SELECT c_customer_sk
    FROM customer
    WHERE c_birth_year BETWEEN 1970 AND 1980
)
SELECT
    cc.cc_name,
    td.t_hour,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    MIN(cr.cr_return_ship_cost) AS min_ship_cost,
    MAX(cr.cr_return_ship_cost) AS max_ship_cost
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN time_dim td
    ON cr.cr_returned_time_sk = td.t_time_sk
JOIN customer cust
    ON cr.cr_returning_customer_sk = cust.c_customer_sk
JOIN customer_address ca
    ON cr.cr_returning_addr_sk = ca.ca_address_sk
WHERE cc.cc_state = 'CA'
  AND cc.cc_employees > 50
  AND td.t_hour BETWEEN 9 AND 17
  AND cr.cr_return_amount > 0
  AND cr.cr_return_ship_cost < 5000
  AND ca.ca_country = 'United States'
  AND cust.c_preferred_cust_flag = 'Y'
  AND cr.cr_returning_customer_sk IN (SELECT customer_sk FROM intersect_customers)
GROUP BY GROUPING SETS (
    (cc.cc_name, td.t_hour),
    (cc.cc_name)
)
ORDER BY total_return_amount DESC
LIMIT 100
