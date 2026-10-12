WITH sampled_sales AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
)
SELECT
    cd.cd_gender,
    cd.cd_education_status,
    COUNT(ss.ss_ticket_number) AS sales_count,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_net_profit) AS avg_profit,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    regexp_extract(c.c_email_address, '@(.+)$') AS email_domain,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
FROM sampled_sales ss
RIGHT OUTER JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
    AND regexp_like(c.c_email_address, '^.*@example\\.com$')
    AND c.c_first_name LIKE 'J%'
GROUP BY
    cd.cd_gender,
    cd.cd_education_status,
    regexp_extract(c.c_email_address, '@(.+)$'),
    CONCAT(c.c_first_name, ' ', c.c_last_name)
ORDER BY total_profit DESC
LIMIT 100
