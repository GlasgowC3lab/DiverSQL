WITH joined AS (
  SELECT
    ca.ca_state,
    r.r_reason_desc,
    ca.ca_gmt_offset,
    ca.ca_location_type
  FROM
    customer_address ca
  JOIN
    reason r
    ON true
  WHERE
    ca.ca_state IN ('AZ','NM','PA','CO','MO')
    AND ca.ca_gmt_offset BETWEEN -9.00 AND -5.00
    AND ca.ca_location_type IN ('condo','apartment')
)
SELECT
  ca_state,
  r_reason_desc,
  address_count,
  avg_gmt_offset,
  rn
FROM (
  SELECT
    ca_state,
    r_reason_desc,
    COUNT(*) AS address_count,
    AVG(ca_gmt_offset) AS avg_gmt_offset,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY AVG(ca_gmt_offset) DESC) AS rn
  FROM
    joined
  GROUP BY
    ca_state,
    r_reason_desc
  HAVING
    COUNT(*) > 5
) sub
WHERE rn <= 3
ORDER BY ca_state, avg_gmt_offset DESC
