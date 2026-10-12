SELECT
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    d_ret.d_date,
    d_ret.d_year,
    d_closed.d_current_day AS store_closed_day,
    d_wp_access.d_day_name AS wp_access_day_name,
    s.s_store_name,
    s.s_manager,
    s.s_number_employees,
    s.s_tax_percentage,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    sr.sr_fee,
    sr.sr_return_tax,
    wp.wp_url,
    wp.wp_type,
    wp.wp_char_count,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY sr.sr_return_amt DESC) AS return_amount_rank
FROM customer_address ca
JOIN store_returns sr
    ON sr.sr_addr_sk = ca.ca_address_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ret.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_ret.d_year = 2020
  AND s.s_state = ca.ca_state
ORDER BY ca.ca_city, sr.sr_return_amt DESC
LIMIT 100
