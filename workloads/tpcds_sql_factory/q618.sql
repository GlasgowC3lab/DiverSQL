WITH sales_by_customer AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    GROUP BY ss.ss_customer_sk
),
returns_by_customer AS (
    SELECT
        cr.cr_refunded_customer_sk AS customer_sk,
        SUM(COALESCE(cr.cr_refunded_cash,0) + COALESCE(cr.cr_store_credit,0) + COALESCE(cr.cr_reversed_charge,0) + COALESCE(cr.cr_fee,0)) AS total_refunds,
        COUNT(*) AS returns_cnt
    FROM catalog_returns cr
    GROUP BY cr.cr_refunded_customer_sk
),
customer_time_stats AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        td.t_hour AS purchase_hour,
        COUNT(*) AS hour_cnt
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    GROUP BY ss.ss_customer_sk, td.t_hour
),
customer_fav_hour AS (
    SELECT
        cts.customer_sk,
        cts.purchase_hour,
        ROW_NUMBER() OVER (PARTITION BY cts.customer_sk ORDER BY cts.hour_cnt DESC) AS rn
    FROM customer_time_stats cts
)
SELECT
    cn.customer_sk,
    cn.total_sales,
    cn.total_refunds,
    cn.net_spend,
    cn.sales_cnt,
    cn.returns_cnt,
    CASE
        WHEN cn.net_spend >= 100000 THEN 'Platinum'
        WHEN cn.net_spend >= 50000 THEN 'Gold'
        WHEN cn.net_spend >= 20000 THEN 'Silver'
        ELSE 'Bronze'
    END AS spend_tier,
    cfh.purchase_hour AS favorite_purchase_hour,
    RANK() OVER (ORDER BY cn.net_spend DESC) AS net_spend_rank
FROM (
    SELECT
        COALESCE(s.customer_sk, r.customer_sk) AS customer_sk,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(r.total_refunds, 0) AS total_refunds,
        (COALESCE(s.total_sales, 0) - COALESCE(r.total_refunds, 0)) AS net_spend,
        COALESCE(s.sales_cnt, 0) AS sales_cnt,
        COALESCE(r.returns_cnt, 0) AS returns_cnt
    FROM sales_by_customer s
    FULL OUTER JOIN returns_by_customer r ON s.customer_sk = r.customer_sk
) cn
LEFT JOIN (
    SELECT customer_sk, purchase_hour
    FROM customer_fav_hour
    WHERE rn = 1
) cfh ON cn.customer_sk = cfh.customer_sk
WHERE cn.net_spend > 0
ORDER BY net_spend_rank
LIMIT 20
