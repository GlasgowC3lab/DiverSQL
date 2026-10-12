WITH promo_agg AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        p.p_discount_active,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        COUNT(DISTINCT s.s_store_id) AS distinct_stores
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_promo_id, p.p_promo_name, p.p_discount_active
)
SELECT
    p_promo_id,
    p_promo_name,
    p_discount_active,
    total_sales,
    total_profit,
    avg_discount,
    distinct_customers,
    distinct_stores,
    sales_rank,
    discount_category
FROM (
    SELECT
        p_promo_id,
        p_promo_name,
        p_discount_active,
        total_sales,
        total_profit,
        avg_discount,
        distinct_customers,
        distinct_stores,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
        CASE WHEN avg_discount > 5 THEN 'High Discount' ELSE 'Low Discount' END AS discount_category
    FROM promo_agg
) t
WHERE sales_rank <= 10
ORDER BY sales_rank
