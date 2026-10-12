WITH cust_agg AS (
    SELECT
        c.c_birth_country,
        COUNT(*) AS cust_cnt,
        AVG(c.c_birth_year) AS avg_birth_year,
        SUM(CASE WHEN c.c_first_shipto_date_sk BETWEEN 2450000 AND 2455000 THEN 1 ELSE 0 END) AS recent_shipto_cnt
    FROM customer c
    WHERE c.c_birth_year BETWEEN 1950 AND 2000
    GROUP BY c.c_birth_country
),
wh_agg AS (
    SELECT
        w.w_country,
        SUM(w.w_warehouse_sq_ft) AS total_sqft,
        COUNT(*) AS wh_cnt,
        AVG(w.w_gmt_offset) AS avg_gmt_offset
    FROM warehouse w
    WHERE w.w_gmt_offset BETWEEN -5 AND 5
    GROUP BY w.w_country
)
SELECT
    ca.c_birth_country AS country,
    ca.cust_cnt,
    ca.avg_birth_year,
    ca.recent_shipto_cnt,
    wa.total_sqft,
    wa.wh_cnt,
    wa.avg_gmt_offset,
    RANK() OVER (ORDER BY ca.cust_cnt DESC) AS cust_rank,
    SUM(wa.total_sqft) OVER (ORDER BY ca.cust_cnt DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sqft
FROM cust_agg ca
JOIN wh_agg wa ON ca.c_birth_country = wa.w_country
WHERE ca.cust_cnt > 10
ORDER BY ca.cust_cnt DESC
LIMIT 15
