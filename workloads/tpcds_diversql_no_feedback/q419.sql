WITH customer_page_sales AS (
    SELECT
        c.c_customer_id AS customer_id,
        wp.wp_type AS page_type,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(wr.wr_return_amt) AS total_return,
        COUNT(*) AS txn_cnt
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
        AND wp.wp_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year BETWEEN 1965 AND 1980
      AND ss.ss_net_profit > 0
      AND wr.wr_fee < 50
    GROUP BY c.c_customer_id, wp.wp_type
    HAVING SUM(ss.ss_net_profit) > 1000
),
aggregated_by_page AS (
    SELECT
        page_type,
        AVG(total_profit) AS avg_profit_per_customer,
        SUM(total_return) AS total_returns_all_customers
    FROM customer_page_sales cps
    WHERE EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_type = cps.page_type
          AND wp2.wp_char_count > 1500
    )
    GROUP BY page_type
)
SELECT
    page_type,
    avg_profit_per_customer,
    total_returns_all_customers
FROM aggregated_by_page
ORDER BY avg_profit_per_customer DESC
LIMIT 100
