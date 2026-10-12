SELECT ca.ca_city,
       ca.ca_state,
       COUNT(DISTINCT cr.cr_order_number) AS orders,
       SUM(cr.cr_return_amount) AS total_return_amount
FROM catalog_returns cr
JOIN customer_address ca
  ON cr.cr_returning_addr_sk = ca.ca_address_sk
WHERE cr.cr_returning_hdemo_sk = 2882
  AND ca.ca_zip = '75124'
GROUP BY ca.ca_city, ca.ca_state
ORDER BY total_return_amount DESC
LIMIT 10
