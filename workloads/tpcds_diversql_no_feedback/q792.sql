SELECT
    ca.ca_state,
    i.i_brand,
    t.t_hour,
    SUM(sr.sr_return_amt) AS total_return_amt,
    COUNT(*) AS return_cnt,
    AVG(sr.sr_return_quantity) AS avg_qty,
    MIN(sr.sr_return_tax) AS min_tax,
    MAX(i.i_current_price) AS max_price,
    (SELECT MAX(i2.i_wholesale_cost)
       FROM item i2
       WHERE i2.i_category = i.i_category) AS max_category_wholesale_cost
FROM store_returns sr
JOIN item i
  ON sr.sr_item_sk = i.i_item_sk
JOIN time_dim t
  ON sr.sr_return_time_sk = t.t_time_sk
JOIN customer c
  ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON sr.sr_addr_sk = ca.ca_address_sk
WHERE t.t_hour BETWEEN 9 AND 17
  AND i.i_manufact_id IN (338, 625)
  AND c.c_birth_month = 7
  AND ca.ca_county = 'Williams County'
  AND ca.ca_gmt_offset = -7.00
  AND EXISTS (
        SELECT 1 FROM item i2
        WHERE i2.i_manufact_id = i.i_manufact_id
          AND i2.i_wholesale_cost > 50.00
      )
GROUP BY ca.ca_state, i.i_brand, t.t_hour, i.i_category
HAVING SUM(sr.sr_return_amt) > 1000
ORDER BY total_return_amt DESC
LIMIT 100
