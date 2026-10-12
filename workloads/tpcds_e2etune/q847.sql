SELECT
    hd.hd_income_band_sk,
    hd.hd_vehicle_count,
    hd.hd_buy_potential,
    COUNT(*) AS num_customers,
    AVG(c.c_birth_year) AS avg_birth_year,
    SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS num_preferred,
    100.0 * SUM(CASE WHEN c.c_salutation = 'Mr.' THEN 1 ELSE 0 END) / COUNT(*) AS pct_mr,
    (SELECT AVG(i.i_current_price) FROM item i WHERE i.i_category = 'Electronics') AS avg_electronics_price,
    (SELECT AVG(i.i_current_price) FROM item i) AS avg_all_price,
    (SELECT r.r_reason_desc FROM reason r WHERE r.r_reason_desc LIKE '%discount%' ORDER BY r.r_reason_id LIMIT 1) AS top_discount_reason
FROM customer c
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE c.c_birth_year BETWEEN 1950 AND 1975
  AND c.c_current_hdemo_sk IS NOT NULL
  AND c.c_salutation IN ('Mr.', 'Mrs.', 'Dr.')
GROUP BY hd.hd_income_band_sk, hd.hd_vehicle_count, hd.hd_buy_potential
HAVING COUNT(*) >= 10
ORDER BY num_customers DESC, avg_birth_year ASC
LIMIT 15
