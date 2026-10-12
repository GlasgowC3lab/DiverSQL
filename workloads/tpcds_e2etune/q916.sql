WITH ib_stats AS (
    SELECT 
        CASE 
            WHEN ib_upper_bound <= 50000 THEN 'low'
            WHEN ib_upper_bound <= 150000 THEN 'medium'
            ELSE 'high'
        END AS income_category,
        AVG(ib_upper_bound) AS avg_upper,
        COUNT(*) AS cnt
    FROM income_band
    GROUP BY 1
), address_agg AS (
    SELECT 
        ca.ca_state,
        ca.ca_city,
        COUNT(*) AS address_cnt,
        AVG(ib.avg_upper) AS avg_income_upper,
        MAX(ib.cnt) AS max_income_band_cnt
    FROM customer_address ca
    JOIN ib_stats ib ON 1=1
    WHERE ca.ca_location_type = 'condo'
      AND ca.ca_gmt_offset = -7.00
    GROUP BY ca.ca_state, ca.ca_city
    HAVING COUNT(*) > 5
), ranked AS (
    SELECT 
        aa.*, 
        ROW_NUMBER() OVER (ORDER BY aa.avg_income_upper DESC) AS rn
    FROM address_agg aa
)
SELECT 
    rn,
    ca_state,
    ca_city,
    address_cnt,
    avg_income_upper,
    max_income_band_cnt
FROM ranked
WHERE rn <= 5
ORDER BY rn
