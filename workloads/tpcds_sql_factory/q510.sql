WITH store_agg AS (
    SELECT ss_customer_sk,
           SUM(ss_net_paid_inc_tax) AS store_net_paid,
           SUM(ss_ext_discount_amt) AS store_discount,
           COUNT(*) AS store_txn_cnt
    FROM store_sales
    GROUP BY ss_customer_sk
),
web_agg AS (
    SELECT ws_bill_customer_sk AS ws_customer_sk,
           SUM(ws_net_paid_inc_tax) AS web_net_paid,
           SUM(ws_ext_discount_amt) AS web_discount,
           COUNT(*) AS web_txn_cnt
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    CASE WHEN c.c_birth_year >= 1990 THEN 'Young' ELSE 'Mature' END AS age_group,
    COALESCE(sa.store_net_paid, 0) + COALESCE(wa.web_net_paid, 0) AS total_net_paid,
    COALESCE(sa.store_discount, 0) + COALESCE(wa.web_discount, 0) AS total_discount,
    (COALESCE(sa.store_discount, 0) + COALESCE(wa.web_discount, 0)) /
        NULLIF(COALESCE(sa.store_txn_cnt, 0) + COALESCE(wa.web_txn_cnt, 0), 0) AS avg_discount_per_txn,
    RANK() OVER (PARTITION BY c.c_birth_month ORDER BY COALESCE(sa.store_net_paid, 0) + COALESCE(wa.web_net_paid, 0) DESC) AS month_sales_rank,
    DENSE_RANK() OVER (ORDER BY c.c_birth_year) AS birth_year_dense_rank,
    CASE WHEN EXISTS (
            SELECT 1
            FROM store_sales ss2
            JOIN promotion p2 ON ss2.ss_promo_sk = p2.p_promo_sk
            WHERE ss2.ss_customer_sk = c.c_customer_sk
              AND p2.p_discount_active = 'Y'
        )
        OR EXISTS (
            SELECT 1
            FROM web_sales ws2
            JOIN promotion p3 ON ws2.ws_promo_sk = p3.p_promo_sk
            WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
              AND p3.p_discount_active = 'Y'
        )
        THEN 'Yes' ELSE 'No' END AS has_active_promo
FROM customer c
LEFT JOIN store_agg sa ON c.c_customer_sk = sa.ss_customer_sk
LEFT JOIN web_agg wa ON c.c_customer_sk = wa.ws_customer_sk
ORDER BY c.c_birth_month, month_sales_rank
LIMIT 200
