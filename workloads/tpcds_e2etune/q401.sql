WITH top_customers AS (
    SELECT c.c_customer_sk
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
    ORDER BY SUM(ss.ss_net_profit) DESC
    LIMIT 1000
),
sales_by_page AS (
    SELECT
        wp.wp_web_page_id,
        wp.wp_type,
        ss.ss_sold_date_sk AS sold_date_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE c.c_customer_sk IN (SELECT c_customer_sk FROM top_customers)
      AND c.c_preferred_cust_flag = 'Y'
      AND wp.wp_type = 'product'
      AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY wp.wp_web_page_id, wp.wp_type, ss.ss_sold_date_sk
)
SELECT
    wp_web_page_id,
    wp_type,
    sold_date_sk,
    total_net_paid,
    total_net_profit,
    avg_discount,
    distinct_customers,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
    SUM(total_net_profit) OVER (PARTITION BY wp_type) AS profit_by_type
FROM sales_by_page
WHERE total_net_profit > 5000
ORDER BY profit_rank
LIMIT 100
