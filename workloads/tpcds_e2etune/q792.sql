WITH cc_agg AS (
  SELECT
    cc_state AS state,
    cc_country AS country,
    SUM(cc_employees) AS total_cc_employees,
    AVG(cc_gmt_offset) AS avg_cc_gmt_offset,
    COUNT(DISTINCT cc_zip) AS distinct_cc_zips
  FROM call_center
  WHERE cc_rec_start_date >= DATE '2000-01-01'
    AND cc_rec_end_date IS NULL
  GROUP BY cc_state, cc_country
),
store_agg AS (
  SELECT
    s_state AS state,
    s_country AS country,
    SUM(s_floor_space) AS total_store_floor_space,
    AVG(s_gmt_offset) AS avg_store_gmt_offset,
    COUNT(DISTINCT s_zip) AS distinct_store_zips,
    COUNT(*) AS store_count
  FROM store
  WHERE s_closed_date_sk IS NULL
  GROUP BY s_state, s_country
),
address_agg AS (
  SELECT
    ca_state AS state,
    ca_country AS country,
    COUNT(DISTINCT ca_address_sk) AS distinct_customer_addresses,
    AVG(ca_gmt_offset) AS avg_address_gmt_offset
  FROM customer_address
  GROUP BY ca_state, ca_country
)
SELECT
  COALESCE(cc.state, s.state, a.state) AS state,
  COALESCE(cc.country, s.country, a.country) AS country,
  cc.total_cc_employees,
  s.total_store_floor_space,
  a.distinct_customer_addresses,
  (cc.avg_cc_gmt_offset - s.avg_store_gmt_offset) AS gmt_offset_diff,
  (cc.total_cc_employees / NULLIF(s.total_store_floor_space, 0)) AS employees_per_floor_space,
  (cc.distinct_cc_zips + s.distinct_store_zips) AS total_distinct_zips,
  RANK() OVER (ORDER BY cc.total_cc_employees DESC) AS employee_rank
FROM cc_agg cc
FULL OUTER JOIN store_agg s
  ON cc.state = s.state AND cc.country = s.country
FULL OUTER JOIN address_agg a
  ON COALESCE(cc.state, s.state) = a.state AND COALESCE(cc.country, s.country) = a.country
WHERE cc.total_cc_employees IS NOT NULL
  AND s.total_store_floor_space > 50000
ORDER BY employee_rank
LIMIT 100
