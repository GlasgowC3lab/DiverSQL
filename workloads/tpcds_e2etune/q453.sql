SELECT
    s.s_state,
    COUNT(*) AS sales_count,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid,
    AVG(cs.cs_net_paid_inc_ship_tax) AS avg_net_paid,
    SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
    RANK() OVER (ORDER BY AVG(cs.cs_net_paid_inc_ship_tax) DESC) AS state_rank
FROM store s
JOIN catalog_sales cs
    ON (cs.cs_ship_customer_sk % 1000) = (s.s_store_sk % 1000)
WHERE cs.cs_net_paid_inc_ship_tax > 5000
  AND cs.cs_ext_ship_cost > 1000
  AND s.s_country = 'United States'
  AND s.s_state IS NOT NULL
GROUP BY s.s_state
HAVING COUNT(*) >= 5
ORDER BY state_rank
LIMIT 10
