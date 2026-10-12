SELECT
  'Customer' AS record_type,
  ca.ca_city AS city,
  hd.hd_buy_potential AS buy_potential,
  COUNT(DISTINCT c.c_customer_id) AS num_customers,
  AVG(
    year(current_date) - c.c_birth_year -
    CASE
      WHEN month(current_date) < c.c_birth_month OR
           (month(current_date) = c.c_birth_month AND day(current_date) < c.c_birth_day)
      THEN 1
      ELSE 0
    END
  ) AS avg_age,
  NULL AS category,
  NULL AS brand,
  NULL AS num_promos,
  NULL AS total_promo_cost,
  NULL AS avg_item_price
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE c.c_birth_year BETWEEN 1960 AND 2000
  AND ca.ca_state = 'CA'
  AND hd.hd_vehicle_count >= 2
GROUP BY ca.ca_city, hd.hd_buy_potential

UNION ALL

SELECT
  'Promotion' AS record_type,
  NULL AS city,
  NULL AS buy_potential,
  NULL AS num_customers,
  NULL AS avg_age,
  i.i_category AS category,
  i.i_brand AS brand,
  COUNT(DISTINCT p.p_promo_id) AS num_promos,
  SUM(p.p_cost) AS total_promo_cost,
  AVG(i.i_current_price) AS avg_item_price
FROM promotion p
JOIN item i ON p.p_item_sk = i.i_item_sk
WHERE p.p_cost > 500
  AND p.p_discount_active = 'Y'
  AND i.i_category IS NOT NULL
GROUP BY i.i_category, i.i_brand
ORDER BY record_type,
  CASE WHEN record_type = 'Customer' THEN num_customers END DESC,
  CASE WHEN record_type = 'Promotion' THEN total_promo_cost END DESC
LIMIT 200
