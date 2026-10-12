SELECT ca.ca_state, COUNT(*) AS cnt FROM customer c JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk WHERE c.c_birth_year = 1943 GROUP BY ca.ca_state
