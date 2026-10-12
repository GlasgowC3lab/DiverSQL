SELECT a.ca_state,
       a.num_addresses,
       a.avg_gmt_offset,
       b.cd_gender,
       b.avg_purchase_estimate,
       b.max_purchase_estimate,
       b.cnt_demo
FROM (
    SELECT ca_state,
           COUNT(*) AS num_addresses,
           AVG(ca_gmt_offset) AS avg_gmt_offset
    FROM customer_address
    WHERE ca_country = 'United States'
      AND ca_zip LIKE '8%'
    GROUP BY ca_state
    HAVING COUNT(*) > 10
) a
JOIN (
    SELECT cd_gender,
           AVG(cd_purchase_estimate) AS avg_purchase_estimate,
           MAX(cd_purchase_estimate) AS max_purchase_estimate,
           COUNT(*) AS cnt_demo
    FROM customer_demographics
    WHERE cd_credit_rating IN ('A', 'B')
      AND cd_marital_status = 'M'
    GROUP BY cd_gender
    HAVING COUNT(*) > 5
) b
ON TRUE
ORDER BY a.num_addresses DESC, b.avg_purchase_estimate ASC
LIMIT 100
