WITH store_shift_agg AS (
    SELECT
        ss.ss_store_sk,
        td.t_shift,
        SUM(ss.ss_ext_sales_price) AS total_ext_sales,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        COUNT(CASE WHEN cd.cd_credit_rating = 'Excellent' THEN 1 END) AS excellent_credit_customers,
        SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_customer_count
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY ss.ss_store_sk, td.t_shift
    HAVING SUM(ss.ss_ext_sales_price) > 0
)
SELECT
    ssa.ss_store_sk,
    ssa.t_shift,
    ssa.total_ext_sales,
    ssa.avg_discount,
    ssa.distinct_customers,
    ssa.excellent_credit_customers,
    ssa.preferred_customer_count,
    DENSE_RANK() OVER (PARTITION BY ssa.t_shift ORDER BY ssa.total_ext_sales DESC) AS store_rank_in_shift,
    CASE
        WHEN ssa.avg_discount > 20 THEN 'High Discount'
        WHEN ssa.avg_discount BETWEEN 10 AND 20 THEN 'Medium Discount'
        ELSE 'Low Discount'
    END AS discount_category
FROM store_shift_agg ssa
ORDER BY ssa.t_shift, store_rank_in_shift
