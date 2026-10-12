WITH unified_sales AS (
    SELECT ss_item_sk AS item_sk, ss_customer_sk AS customer_sk, ss_net_paid AS net_paid, ss_sold_date_sk AS sold_date_sk
    FROM store_sales
    UNION ALL
    SELECT cs_item_sk, cs_bill_customer_sk, cs_net_paid, cs_sold_date_sk
    FROM catalog_sales
    UNION ALL
    SELECT ws_item_sk, ws_bill_customer_sk, ws_net_paid, ws_sold_date_sk
    FROM web_sales
),
sales_enriched AS (
    SELECT
        us.item_sk,
        us.customer_sk,
        us.net_paid,
        d.d_year,
        i.i_product_name,
        i.i_item_id,
        c.c_email_address,
        lower(regexp_replace(i.i_product_name, '[^a-zA-Z0-9]', '')) AS norm_product_name,
        reverse(i.i_product_name) AS rev_product_name,
        substring(i.i_product_name, 1, 10) AS product_name_prefix,
        length(i.i_product_name) AS product_name_len,
        regexp_extract(c.c_email_address, '@([^@]+)$', 1) AS email_domain,
        length(regexp_extract(c.c_email_address, '@([^@]+)$', 1)) AS domain_len,
        replace(lower(i.i_product_name), ' ', '_') AS product_name_underscored,
        translate(i.i_product_name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') AS product_name_lowercase
    FROM unified_sales us
    JOIN item i ON us.item_sk = i.i_item_sk
    JOIN customer c ON us.customer_sk = c.c_customer_sk
    JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
),
agg AS (
    SELECT
        norm_product_name,
        rev_product_name,
        product_name_prefix,
        product_name_len,
        email_domain,
        domain_len,
        product_name_underscored,
        product_name_lowercase,
        sum(net_paid) AS total_net_paid,
        avg(net_paid) AS avg_net_paid,
        count(*) AS sales_cnt,
        count(distinct customer_sk) AS distinct_customers
    FROM sales_enriched
    GROUP BY
        norm_product_name,
        rev_product_name,
        product_name_prefix,
        product_name_len,
        email_domain,
        domain_len,
        product_name_underscored,
        product_name_lowercase
),
ranked AS (
    SELECT
        *,
        row_number() OVER (PARTITION BY email_domain ORDER BY total_net_paid DESC) AS domain_product_rank
    FROM agg
)
SELECT
    email_domain,
    norm_product_name,
    rev_product_name,
    product_name_prefix,
    product_name_len,
    product_name_underscored,
    product_name_lowercase,
    total_net_paid,
    avg_net_paid,
    sales_cnt,
    distinct_customers,
    domain_product_rank
FROM ranked
WHERE domain_product_rank = 1
ORDER BY total_net_paid DESC
LIMIT 100
