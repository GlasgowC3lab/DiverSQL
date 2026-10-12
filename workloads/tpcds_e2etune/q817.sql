WITH promo_agg AS (
    SELECT 
        cp.cp_department,
        hd.hd_income_band_sk,
        d_start.d_year AS promo_year,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        SUM(p.p_cost) AS total_promo_cost
    FROM promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end   ON p.p_end_date_sk = d_end.d_date_sk
    JOIN catalog_page cp 
      ON cp.cp_start_date_sk <= p.p_end_date_sk 
     AND cp.cp_end_date_sk   >= p.p_start_date_sk
    JOIN customer c 
      ON c.c_first_sales_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    JOIN household_demographics hd 
      ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE d_start.d_year = 2020
      AND p.p_cost > 500
      AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
      AND cp.cp_department IS NOT NULL
    GROUP BY 
        cp.cp_department,
        hd.hd_income_band_sk,
        d_start.d_year
)
SELECT 
    pa.cp_department,
    pa.hd_income_band_sk,
    pa.promo_year,
    pa.distinct_customers,
    pa.total_promo_cost,
    RANK() OVER (PARTITION BY pa.promo_year ORDER BY pa.total_promo_cost DESC) AS dept_rank_by_cost
FROM promo_agg pa
ORDER BY pa.total_promo_cost DESC
LIMIT 50
