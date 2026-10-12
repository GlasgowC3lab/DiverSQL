WITH full_ca AS (
   SELECT
       c.c_customer_id,
       ca.ca_state,
       ca.ca_country,
       ARRAY[ca.ca_state, ca.ca_country] AS loc_array
   FROM customer c
   FULL OUTER JOIN customer_address ca
       ON c.c_current_addr_sk = ca.ca_address_sk
   WHERE c.c_birth_month IN (1, 7, 10)
     AND ca.ca_gmt_offset = -6.00
),
join_ca AS (
   SELECT
       c.c_customer_id,
       ca.ca_state,
       ca.ca_country,
       ARRAY[ca.ca_state, ca.ca_country] AS loc_array
   FROM customer c
   JOIN customer_address ca
       ON c.c_current_addr_sk = ca.ca_address_sk
   WHERE c.c_birth_month IN (3, 2)
     AND ca.ca_gmt_offset = -5.00
),
expanded_full AS (
   SELECT
       f.c_customer_id,
       f.ca_state,
       f.ca_country,
       loc AS location
   FROM full_ca f
   CROSS JOIN UNNEST(f.loc_array) AS t(loc)
),
expanded_join AS (
   SELECT
       j.c_customer_id,
       j.ca_state,
       j.ca_country,
       loc AS location
   FROM join_ca j
   CROSS JOIN UNNEST(j.loc_array) AS t(loc)
),
unioned AS (
   SELECT c_customer_id, ca_state, ca_country, location
   FROM expanded_full
   UNION
   SELECT c_customer_id, ca_state, ca_country, location
   FROM expanded_join
),
ranked AS (
   SELECT
       c_customer_id,
       ca_state,
       ca_country,
       location,
       row_number() OVER (PARTITION BY ca_state ORDER BY c_customer_id) AS rn
   FROM unioned
)
SELECT
   c_customer_id,
   ca_state,
   ca_country,
   location
FROM ranked
WHERE rn <= 5
ORDER BY ca_state, rn
LIMIT 100
