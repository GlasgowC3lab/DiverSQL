SELECT
    d_store_closed.d_year AS store_close_year,
    d_store_closed.d_moy AS store_close_month,
    d_cc_open.d_year AS cc_open_year,
    cc.cc_division AS call_center_division,
    CASE WHEN cc.cc_tax_percentage > 5 THEN 'HIGH_TAX' ELSE 'LOW_TAX' END AS tax_category,
    CASE WHEN ca.ca_state IN ('CA','NY','TX') THEN ca.ca_state ELSE 'OTHER' END AS customer_state_group,
    COUNT(DISTINCT s.s_store_sk) AS num_stores,
    SUM(s.s_floor_space) AS total_floor_space,
    COUNT(DISTINCT cc.cc_call_center_sk) AS num_call_centers,
    SUM(cc.cc_employees) AS total_call_center_employees,
    AVG(cc.cc_tax_percentage) AS avg_call_center_tax,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    AVG(d_store_closed.d_year - c.c_birth_year) AS avg_customer_age_at_store_close,
    SUM(CASE WHEN d_c_first_ship.d_moy = d_store_closed.d_moy THEN 1 ELSE 0 END) AS customers_ship_same_month,
    SUM(CASE WHEN d_c_last_review.d_year = d_store_closed.d_year THEN 1 ELSE 0 END) AS customers_review_same_year,
    ROUND(SUM(s.s_floor_space) / NULLIF(SUM(cc.cc_employees), 0), 2) AS floor_space_per_employee
FROM
    store s
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN customer c
        ON c.c_first_sales_date_sk = d_store_closed.d_date_sk
    JOIN date_dim d_c_first_ship
        ON c.c_first_shipto_date_sk = d_c_first_ship.d_date_sk
    JOIN date_dim d_c_last_review
        ON c.c_last_review_date = d_c_last_review.d_date_sk
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
WHERE
    d_store_closed.d_year BETWEEN 2000 AND 2025
GROUP BY
    d_store_closed.d_year,
    d_store_closed.d_moy,
    d_cc_open.d_year,
    cc.cc_division,
    CASE WHEN cc.cc_tax_percentage > 5 THEN 'HIGH_TAX' ELSE 'LOW_TAX' END,
    CASE WHEN ca.ca_state IN ('CA','NY','TX') THEN ca.ca_state ELSE 'OTHER' END
ORDER BY
    d_store_closed.d_year,
    d_store_closed.d_moy,
    d_cc_open.d_year,
    cc.cc_division,
    tax_category,
    customer_state_group
