WITH base AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_item_sk,
        ss.ss_net_paid,
        ss.ss_quantity,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_credit_rating,
        i.i_category,
        i.i_category_id,
        i.i_product_name
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_net_paid > 100
      AND regexp_like(i.i_product_name, '^.*[0-9]{2}.*$')
      AND c.c_email_address LIKE '%@example.%'
),
email_parts AS (
    SELECT
        b.*,
        split(b.c_email_address, '@')[1] AS email_domain
    FROM base b
),
exploded AS (
    SELECT
        e.*,
        t.email_token
    FROM email_parts e
    CROSS JOIN UNNEST(split(email_domain, '\\.')) AS t(email_token)
)
SELECT
    ROW_NUMBER() OVER (ORDER BY agg.total_net_paid DESC) AS row_num,
    agg.gender,
    agg.credit_rating,
    agg.category,
    agg.category_id,
    agg.unique_customers,
    agg.total_net_paid,
    agg.avg_quantity,
    agg.full_name,
    agg.email_token
FROM (
    SELECT
        cd_gender AS gender,
        cd_credit_rating AS credit_rating,
        i_category AS category,
        i_category_id AS category_id,
        COUNT(DISTINCT ss_customer_sk) AS unique_customers,
        SUM(ss_net_paid) AS total_net_paid,
        AVG(ss_quantity) AS avg_quantity,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        email_token
    FROM exploded
    WHERE email_token <> ''
    GROUP BY
        cd_gender,
        cd_credit_rating,
        i_category,
        i_category_id,
        c_first_name,
        c_last_name,
        email_token
) agg
ORDER BY agg.total_net_paid DESC
LIMIT 100
