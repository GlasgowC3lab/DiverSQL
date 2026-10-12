WITH customer_store AS (
   SELECT
       c.c_customer_id,
       c.c_birth_country,
       c.c_preferred_cust_flag,
       c.c_birth_month,
       s.s_market_id,
       s.s_country,
       s.s_state,
       s.s_floor_space,
       s.s_tax_percentage
   FROM customer c
   JOIN store s
     ON c.c_birth_country = s.s_country
   WHERE s.s_state = 'CA'
),
market_agg AS (
   SELECT
       cs.s_market_id,
       cs.s_country,
       COUNT(DISTINCT cs.c_customer_id) AS num_customers,
       SUM(CASE WHEN cs.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_customers,
       AVG(cs.s_floor_space) AS avg_floor_space,
       AVG(cs.s_tax_percentage) AS avg_store_tax
   FROM customer_store cs
   WHERE cs.c_birth_month IN (4, 7, 10)
   GROUP BY cs.s_market_id, cs.s_country
   HAVING COUNT(DISTINCT cs.c_customer_id) > 10
)
SELECT
    ma.s_market_id,
    ma.s_country,
    ma.num_customers,
    ma.preferred_customers,
    ma.avg_floor_space,
    ma.avg_store_tax,
    AVG(w.web_tax_percentage) AS avg_website_tax,
    (ma.avg_store_tax - AVG(w.web_tax_percentage)) AS tax_diff,
    RANK() OVER (ORDER BY ma.num_customers DESC) AS cust_rank
FROM market_agg ma
JOIN web_site w
  ON ma.s_market_id = w.web_mkt_id
WHERE w.web_state = 'CA'
GROUP BY ma.s_market_id, ma.s_country, ma.num_customers, ma.preferred_customers, ma.avg_floor_space, ma.avg_store_tax
ORDER BY cust_rank
LIMIT 10
