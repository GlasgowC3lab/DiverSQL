WITH cc_promo AS (
    SELECT
        cc.cc_state,
        cc.cc_division,
        cc.cc_tax_percentage,
        cc.cc_employees,
        cc.cc_sq_ft,
        p.p_cost
    FROM call_center cc
    JOIN promotion p
        ON cc.cc_open_date_sk = p.p_start_date_sk
    WHERE cc.cc_rec_start_date >= DATE '2000-01-01'
      AND cc.cc_state IN ('TN', 'LA', 'GA')
),
agg AS (
    SELECT
        cc_state,
        cc_division,
        COUNT(*) AS num_centers,
        SUM(cc_employees) AS total_employees,
        AVG(cc_tax_percentage) AS avg_tax_pct,
        approx_percentile(cc_sq_ft, 0.5) AS median_sq_ft,
        SUM(p_cost) AS total_promo_cost
    FROM cc_promo
    GROUP BY cc_state, cc_division
    HAVING COUNT(*) > 1
)
SELECT
    cc_state,
    cc_division,
    num_centers,
    total_employees,
    avg_tax_pct,
    median_sq_ft,
    total_promo_cost,
    RANK() OVER (PARTITION BY cc_state ORDER BY avg_tax_pct DESC) AS tax_rank,
    SUM(total_promo_cost) OVER (PARTITION BY cc_state) AS total_promo_cost_state
FROM agg
ORDER BY cc_state, tax_rank
