WITH all_sales AS (
    SELECT cs.cs_bill_customer_sk AS customer_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_net_paid AS net_paid
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_customer_sk,
           ss.ss_item_sk,
           ss.ss_net_paid
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_bill_customer_sk,
           ws.ws_item_sk,
           ws.ws_net_paid
    FROM web_sales ws
),
customer_item_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_salutation,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        lower(split_part(c.c_email_address, '@', 2)) AS email_domain,
        concat_ws(' ', c.c_salutation, c.c_first_name, c.c_last_name) AS full_name,
        length(concat_ws(' ', c.c_salutation, c.c_first_name, c.c_last_name)) AS full_name_len,
        regexp_replace(c.c_email_address, '[^a-zA-Z0-9@.]', '') AS email_clean,
        sum(coalesce(asales.net_paid, 0)) AS total_spent,
        count(DISTINCT asales.item_sk) AS distinct_items,
        array_join(
            array_agg(DISTINCT concat(
                lower(regexp_replace(i.i_item_desc, '\\s+', '_')),
                '-',
                upper(i.i_color),
                '-',
                substring(i.i_size, 1, 3)
            )),
            '|'
        ) AS item_signature_concat,
        sum(cardinality(split(i.i_item_desc, '\\s+'))) AS total_desc_word_count
    FROM customer c
    LEFT JOIN all_sales asales
        ON c.c_customer_sk = asales.customer_sk
    LEFT JOIN item i
        ON asales.item_sk = i.i_item_sk
    GROUP BY 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_salutation,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        lower(split_part(c.c_email_address, '@', 2)),
        concat_ws(' ', c.c_salutation, c.c_first_name, c.c_last_name),
        length(concat_ws(' ', c.c_salutation, c.c_first_name, c.c_last_name)),
        regexp_replace(c.c_email_address, '[^a-zA-Z0-9@.]', '')
),
domain_agg AS (
    SELECT 
        email_domain,
        count(*) AS num_customers,
        sum(total_spent) AS domain_total_spent,
        avg(total_spent) AS domain_avg_spent,
        sum(distinct_items) AS domain_total_distinct_items,
        max(full_name_len) AS max_name_length,
        count_if(regexp_like(email_domain, '.*mail.*')) AS mail_like_count,
        max(length(item_signature_concat)) AS max_signature_len,
        sum(total_desc_word_count) AS total_desc_words
    FROM customer_item_sales
    GROUP BY email_domain
)
SELECT 
    d.email_domain,
    d.num_customers,
    d.domain_total_spent,
    d.domain_avg_spent,
    d.domain_total_distinct_items,
    d.max_name_length,
    d.mail_like_count,
    d.max_signature_len,
    d.total_desc_words,
    (
        SELECT cis.item_signature_concat
        FROM customer_item_sales cis
        WHERE cis.email_domain = d.email_domain
        ORDER BY cis.total_spent DESC
        LIMIT 1
    ) AS sample_item_signature
FROM domain_agg d
ORDER BY d.domain_total_spent DESC
LIMIT 20
