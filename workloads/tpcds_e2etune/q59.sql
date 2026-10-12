SELECT
  a.ca_state,
  a.avg_gmt_offset,
  a.address_cnt,
  b.hd_vehicle_count,
  b.avg_income_band_sk,
  c.wp_type,
  c.avg_char_count,
  c.total_image_count,
  RANK() OVER (ORDER BY a.avg_gmt_offset DESC, c.total_image_count DESC) AS state_type_rank
FROM (
  SELECT
    ca_state,
    AVG(ca_gmt_offset) AS avg_gmt_offset,
    COUNT(*) AS address_cnt
  FROM customer_address
  WHERE ca_country = 'United States'
    AND ca_gmt_offset > -6.00
  GROUP BY ca_state
) a
CROSS JOIN (
  SELECT
    hd_vehicle_count,
    AVG(hd_income_band_sk) AS avg_income_band_sk,
    COUNT(*) AS hd_cnt
  FROM household_demographics
  WHERE hd_vehicle_count > 0
  GROUP BY hd_vehicle_count
) b
CROSS JOIN (
  SELECT
    wp_type,
    AVG(wp_char_count) AS avg_char_count,
    SUM(wp_image_count) AS total_image_count,
    COUNT(*) AS page_cnt
  FROM web_page
  WHERE wp_char_count > 500
  GROUP BY wp_type
) c
ORDER BY state_type_rank
LIMIT 100
