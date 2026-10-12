WITH open_dates AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_market_manager,
        cc.cc_county,
        cc.cc_gmt_offset,
        cc.cc_tax_percentage,
        cc.cc_employees,
        od.d_year AS open_year
    FROM call_center cc
    JOIN date_dim od
      ON cc.cc_open_date_sk = od.d_date_sk
    WHERE cc.cc_gmt_offset IN (-5.00, -6.00)
      AND cc.cc_hours = '8AM-4PM'
      AND od.d_year BETWEEN 2010 AND 2020
),
close_dates AS (
    SELECT
        cc.cc_call_center_sk,
        cd.d_year AS close_year
    FROM call_center cc
    JOIN date_dim cd
      ON cc.cc_closed_date_sk = cd.d_date_sk
    WHERE cd.d_year >= 2015
),
aggregated AS (
    SELECT
        od.cc_market_manager AS market_manager,
        od.cc_county AS county,
        od.open_year,
        cd.close_year,
        COUNT(*) AS num_call_centers,
        SUM(od.cc_employees) AS total_employees,
        AVG(od.cc_tax_percentage) AS avg_tax_pct,
        AVG(od.cc_gmt_offset) AS avg_gmt_offset
    FROM open_dates od
    JOIN close_dates cd
      ON od.cc_call_center_sk = cd.cc_call_center_sk
    WHERE cd.close_year >= od.open_year
    GROUP BY
        od.cc_market_manager,
        od.cc_county,
        od.open_year,
        cd.close_year
    HAVING COUNT(*) >= 2
)
SELECT
    market_manager,
    county,
    open_year,
    close_year,
    num_call_centers,
    total_employees,
    avg_tax_pct,
    ROUND(avg_gmt_offset, 2) AS avg_gmt_offset,
    ROW_NUMBER() OVER (PARTITION BY market_manager ORDER BY total_employees DESC) AS employee_rank
FROM aggregated
ORDER BY avg_tax_pct DESC, total_employees DESC
LIMIT 100
