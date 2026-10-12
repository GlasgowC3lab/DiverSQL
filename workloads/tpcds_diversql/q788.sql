WITH filtered_customer AS (
    SELECT *
    FROM tpcds.customer
    WHERE c_preferred_cust_flag = 'Y'
      AND c_birth_month IN (1, 2, 3, 4, 5, 6)
      AND c_birth_day > 10
      AND c_birth_year BETWEEN 1960 AND 1990
),
sampled_pages AS (
    SELECT *
    FROM tpcds.web_page TABLESAMPLE BERNOULLI (10)
    WHERE wp_link_count >= 10
      AND wp_type IN ('product', 'category')
      AND wp_rec_end_date > DATE '2000-01-01'
      AND wp_image_count IS NOT NULL
),
customer_page_agg AS (
    SELECT
        c.c_customer_sk,
        COUNT(p.wp_web_page_sk) AS page_cnt,
        SUM(p.wp_link_count) AS total_links,
        AVG(p.wp_char_count) AS avg_char_cnt,
        CASE WHEN SUM(p.wp_image_count) > 100 THEN 'high' ELSE 'low' END AS image_density
    FROM filtered_customer c
    JOIN sampled_pages p
        ON p.wp_customer_sk = c.c_customer_sk
    WHERE EXISTS (
        SELECT 1
        FROM tpcds.web_page wp2
        WHERE wp2.wp_customer_sk = c.c_customer_sk
          AND wp2.wp_link_count > 20
    )
    GROUP BY c.c_customer_sk
),
final_agg AS (
    SELECT
        image_density,
        AVG(total_links) AS avg_total_links,
        SUM(page_cnt) AS sum_page_cnt,
        COUNT(*) AS cust_cnt
    FROM customer_page_agg
    GROUP BY image_density
    HAVING SUM(page_cnt) > 5
)
SELECT
    ROW_NUMBER() OVER (ORDER BY avg_total_links DESC) AS row_num,
    image_density,
    avg_total_links,
    sum_page_cnt,
    cust_cnt
FROM final_agg
ORDER BY avg_total_links DESC
LIMIT 100
