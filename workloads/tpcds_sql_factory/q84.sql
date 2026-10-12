WITH customer_spend AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_birth_year,
        c.c_birth_month,
        CASE 
            WHEN c.c_birth_year < 1960 THEN 'Pre-1960'
            WHEN c.c_birth_year BETWEEN 1960 AND 1979 THEN '1960s-70s'
            WHEN c.c_birth_year BETWEEN 1980 AND 1999 THEN '80s-90s'
            ELSE '2000s+'
        END AS birth_decade_group,
        SUM(ss.ss_ext_sales_price) AS total_spent,
        AVG(ss.ss_net_paid) AS avg_net_paid,
        COUNT(*) AS purchase_count,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN ss.ss_ext_discount_amt ELSE 0 END) AS total_discount_active_promo,
        COUNT(DISTINCT s.s_store_id) AS distinct_store_count
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        c.c_birth_month,
        CASE 
            WHEN c.c_birth_year < 1960 THEN 'Pre-1960'
            WHEN c.c_birth_year BETWEEN 1960 AND 1979 THEN '1960s-70s'
            WHEN c.c_birth_year BETWEEN 1980 AND 1999 THEN '80s-90s'
            ELSE '2000s+'
        END
)
SELECT
    c_customer_id,
    full_name,
    c_birth_year,
    c_birth_month,
    birth_decade_group,
    total_spent,
    avg_net_paid,
    purchase_count,
    total_discount_active_promo,
    distinct_store_count,
    RANK() OVER (PARTITION BY birth_decade_group ORDER BY total_spent DESC) AS spend_rank_in_group,
    CASE 
        WHEN total_spent > 5000 THEN 'VIP'
        WHEN total_spent > 1000 THEN 'Gold'
        ELSE 'Regular'
    END AS customer_tier
FROM customer_spend
WHERE purchase_count >= 5
ORDER BY birth_decade_group, spend_rank_in_group
