SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    c_birth_day,
    c_birth_month,
    c_birth_year
FROM tpcds.customer
WHERE c_birth_day = 8
  AND c_first_name = 'Lee'
