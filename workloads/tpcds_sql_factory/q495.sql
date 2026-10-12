WITH monthly_sales AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_type,
        cc.cc_division_name,
        d.d_year,
        d.d_current_month,
        SUM(ss.ss_net_paid_inc_tax) AS monthly_net_paid,
        SUM(ss.ss_ext_discount_amt) AS total_discount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON d.d_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
    JOIN call_center cc ON d.d_date_sk BETWEEN cc.cc_open_date_sk AND cc.cc_closed_date_sk
    GROUP BY cp.cp_catalog_page_id, cp.cp_type, cc.cc_division_name, d.d_year, d.d_current_month
    HAVING SUM(ss.ss_net_paid_inc_tax) > 0
),
monthly_with_lag AS (
    SELECT
        *,
        LAG(monthly_net_paid) OVER (PARTITION BY cp_catalog_page_id ORDER BY d_year, d_current_month) AS prev_month_net_paid
    FROM monthly_sales
)
SELECT
    cp_catalog_page_id,
    cp_type,
    cc_division_name,
    d_year,
    d_current_month,
    monthly_net_paid,
    total_discount,
    prev_month_net_paid,
    CASE 
        WHEN prev_month_net_paid IS NULL OR prev_month_net_paid = 0 THEN NULL
        ELSE ((monthly_net_paid - prev_month_net_paid) / prev_month_net_paid) * 100
    END AS mom_growth_pct,
    CASE WHEN total_discount > 1000 THEN 'High Discount' ELSE 'Low Discount' END AS discount_category,
    RANK() OVER (PARTITION BY d_year, d_current_month ORDER BY monthly_net_paid DESC) AS monthly_sales_rank
FROM monthly_with_lag
ORDER BY d_year, d_current_month, monthly_sales_rank
LIMIT 200
