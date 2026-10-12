WITH cc_agg AS (
    SELECT
        cc.cc_division_name,
        SUM(cc.cc_sq_ft) AS total_sq_ft,
        AVG(cc.cc_employees) AS avg_employees
    FROM call_center cc
    WHERE cc.cc_country = 'United States'
      AND cc.cc_sq_ft > 0
      AND cc.cc_closed_date_sk IS NOT NULL
    GROUP BY cc.cc_division_name
),
inv_agg AS (
    SELECT
        cc.cc_division_name,
        d.d_year,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        AVG(i.inv_quantity_on_hand) AS avg_qty
    FROM call_center cc
    JOIN inventory i
        ON i.inv_date_sk BETWEEN cc.cc_open_date_sk AND cc.cc_closed_date_sk
    JOIN date_dim d
        ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2015 AND 2022
    GROUP BY cc.cc_division_name, d.d_year
)
SELECT
    i.cc_division_name,
    i.d_year,
    i.total_qty,
    i.avg_qty,
    c.total_sq_ft,
    i.total_qty / NULLIF(c.total_sq_ft, 0) AS qty_per_sqft,
    RANK() OVER (PARTITION BY i.d_year ORDER BY i.total_qty DESC) AS division_rank
FROM inv_agg i
JOIN cc_agg c
    ON i.cc_division_name = c.cc_division_name
ORDER BY i.d_year, division_rank
