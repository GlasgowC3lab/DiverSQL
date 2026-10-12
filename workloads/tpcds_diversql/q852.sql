WITH sampled_sales AS (
    SELECT ws.*
    FROM web_sales ws
    TABLESAMPLE BERNOULLI (10)
    WHERE ws.ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2000
    )
),

sales_agg AS (
    SELECT
        ss.ws_bill_customer_sk AS cust_sk,
        SUM(ss.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        MIN(ss.ws_sold_date_sk) AS first_sold_date_sk
    FROM sampled_sales ss
    JOIN date_dim d ON ss.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ss.ws_web_page_sk = wp.wp_web_page_sk
    WHERE regexp_like(wp.wp_url, '^https?://[^/]+/sports/')
      AND wp.wp_autogen_flag = 'N'
    GROUP BY ss.ws_bill_customer_sk
),

customers_no_returns AS (
    SELECT c.c_customer_sk
    FROM customer c
    WHERE c.c_customer_sk IN (SELECT cust_sk FROM sales_agg)
    EXCEPT
    SELECT wr.wr_refunded_customer_sk
    FROM web_returns wr
    JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2000
),

final_customers AS (
    SELECT
        sa.cust_sk,
        c.c_first_name,
        c.c_last_name,
        sa.total_profit,
        sa.sales_cnt,
        ROW_NUMBER() OVER (PARTITION BY sa.cust_sk ORDER BY sa.total_profit DESC) AS rn
    FROM sales_agg sa
    JOIN customer c ON sa.cust_sk = c.c_customer_sk
    WHERE sa.cust_sk IN (SELECT c_customer_sk FROM customers_no_returns)
      AND EXISTS (
          SELECT 1
          FROM web_sales ws2
          JOIN promotion p ON ws2.ws_promo_sk = p.p_promo_sk
          JOIN date_dim d3 ON p.p_start_date_sk = d3.d_date_sk
          WHERE ws2.ws_bill_customer_sk = sa.cust_sk
            AND d3.d_year = 2000
            AND p.p_promo_id LIKE 'PROMO%'
      )
)
SELECT
    fc.cust_sk,
    CONCAT(fc.c_first_name, ' ', fc.c_last_name) AS full_name,
    fc.total_profit,
    fc.sales_cnt,
    fc.rn,
    regexp_extract(wp.wp_url, '://([^/]+)/', 1) AS domain
FROM final_customers fc
JOIN web_sales ws ON ws.ws_bill_customer_sk = fc.cust_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE fc.rn <= 10
ORDER BY fc.total_profit DESC
LIMIT 100
