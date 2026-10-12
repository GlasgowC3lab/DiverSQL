SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    s.s_country AS store_country,
    s.s_tax_percentage AS store_tax_pct,
    cc.cc_call_center_id,
    cc.cc_name AS cc_name,
    cc.cc_state AS cc_state,
    cc.cc_tax_percentage AS cc_tax_pct,
    ca.ca_address_id,
    ca.ca_city AS address_city,
    ca.ca_state AS address_state,
    ca.ca_zip AS address_zip,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    c.c_birth_year,
    d_date.d_year AS transaction_year,
    d_cc_open.d_year AS cc_open_year,
    d_c_shipto.d_year AS shipto_year,
    d_c_review.d_year AS review_year,
    (d_date.d_year - c.c_birth_year) AS customer_age_at_transaction,
    (cc.cc_tax_percentage + s.s_tax_percentage) / 2.0 AS avg_tax_pct,
    date_diff('day', d_cc_open.d_date, d_date.d_date) AS cc_duration_days,
    CASE WHEN d_c_shipto.d_year = d_date.d_year THEN 1 ELSE 0 END AS shipto_same_year_as_store_closed,
    row_number() OVER (PARTITION BY s.s_store_id ORDER BY c.c_customer_id) AS customer_rank_in_store
FROM store s
JOIN date_dim d_date
    ON s.s_closed_date_sk = d_date.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_date.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN customer c
    ON c.c_first_sales_date_sk = d_date.d_date_sk
JOIN date_dim d_c_shipto
    ON c.c_first_shipto_date_sk = d_c_shipto.d_date_sk
JOIN date_dim d_c_review
    ON c.c_last_review_date = d_c_review.d_date_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
WHERE s.s_state IS NOT NULL
  AND cc.cc_state IS NOT NULL
  AND ca.ca_state IS NOT NULL
ORDER BY s.s_store_id, customer_rank_in_store
LIMIT 100
