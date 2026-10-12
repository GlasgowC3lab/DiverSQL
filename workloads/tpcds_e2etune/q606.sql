SELECT
    ca.ca_state AS state,
    hd.hd_buy_potential AS buy_potential,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    AVG(c.c_birth_year) AS avg_birth_year,
    SUM(hd.hd_vehicle_count) AS total_vehicles,
    RANK() OVER (ORDER BY COUNT(DISTINCT c.c_customer_sk) DESC) AS state_rank,
    (SELECT COUNT(*) FROM promotion WHERE p_discount_active = 'Y') AS active_promo_count,
    (SELECT SUM(p_cost) FROM promotion WHERE p_discount_active = 'Y') AS total_active_promo_cost,
    (SELECT COUNT(*) FROM catalog_page WHERE cp_type = 'monthly' AND cp_catalog_number = 3) AS monthly_catalog_page_count
FROM customer c
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE c.c_birth_year BETWEEN 1950 AND 2000
  AND ca.ca_country = 'United States'
GROUP BY ca.ca_state, hd.hd_buy_potential
HAVING COUNT(DISTINCT c.c_customer_sk) > 5
ORDER BY num_customers DESC
LIMIT 50
