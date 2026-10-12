WITH catalog_part AS (
  SELECT
    cr.cr_returned_date_sk AS date_sk,
    cr.cr_return_amount        AS return_amount,
    cr.cr_return_quantity      AS return_quantity,
    ca.ca_state                AS state,
    sm.sm_carrier              AS carrier,
    'catalog'                  AS source
  FROM tpcds.catalog_returns cr
  JOIN tpcds.date_dim d        ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN tpcds.customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  JOIN tpcds.ship_mode sm      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE d.d_year = 2000
    AND sm.sm_carrier = 'DIAMOND'
),
store_part AS (
  SELECT
    sr.sr_returned_date_sk AS date_sk,
    sr.sr_return_amt       AS return_amount,
    sr.sr_return_quantity  AS return_quantity,
    ca.ca_state            AS state,
    CAST(NULL AS varchar)  AS carrier,
    'store'                AS source
  FROM tpcds.store_returns sr
  JOIN tpcds.date_dim d        ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN tpcds.customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2001
    AND ca.ca_county = 'Mifflin County'
)
SELECT
  d.d_year,
  u.state,
  u.carrier,
  u.source,
  SUM(u.return_amount)   AS total_return_amount,
  SUM(u.return_quantity) AS total_return_quantity
FROM (
  SELECT * FROM catalog_part
  UNION ALL
  SELECT * FROM store_part
) u
JOIN tpcds.date_dim d ON u.date_sk = d.d_date_sk
GROUP BY CUBE (d.d_year, u.state, u.carrier, u.source)
ORDER BY total_return_amount DESC
LIMIT 100
