WITH cc_yearly AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_employees,
        cc.cc_country,
        d_cc.d_year,
        cc.cc_tax_percentage
    FROM call_center cc
    JOIN date_dim d_cc ON cc.cc_closed_date_sk = d_cc.d_date_sk
),
store_returns_yearly AS (
    SELECT
        s.s_store_sk,
        s.s_country,
        d_s.d_year,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_qty
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_s ON s.s_closed_date_sk = d_s.d_date_sk
    GROUP BY s.s_store_sk, s.s_country, d_s.d_year
)
SELECT
    cc.cc_call_center_sk,
    cc.cc_name,
    cc.cc_country,
    cc.d_year AS cc_year,
    cc.cc_employees,
    SUM(sr_yr.total_return_amt) AS agg_store_return_amt,
    SUM(sr_yr.total_return_qty) AS agg_store_return_qty,
    CASE 
        WHEN SUM(sr_yr.total_return_amt) > 100000 THEN 'HIGH_RETURN_VOLUME'
        ELSE 'NORMAL_RETURN_VOLUME'
    END AS return_volume_category,
    DENSE_RANK() OVER (ORDER BY cc.cc_employees DESC) AS employee_rank,
    ROUND(cc.cc_tax_percentage * 0.01, 4) AS cc_tax_rate,
    ROUND(SUM(sr_yr.total_return_amt) * (1 + cc.cc_tax_percentage/100), 2) AS tax_adjusted_return_total
FROM cc_yearly cc
LEFT JOIN store_returns_yearly sr_yr
    ON cc.cc_country = sr_yr.s_country
    AND cc.d_year = sr_yr.d_year
GROUP BY cc.cc_call_center_sk, cc.cc_name, cc.cc_country, cc.d_year, cc.cc_employees, cc.cc_tax_percentage
HAVING SUM(sr_yr.total_return_amt) IS NOT NULL
ORDER BY employee_rank, agg_store_return_amt DESC
LIMIT 100
