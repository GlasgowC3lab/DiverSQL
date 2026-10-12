WITH email_domains AS (
    SELECT
        c.c_customer_sk,
        lower(regexp_extract(c.c_email_address, '@([^@]+)$', 1)) AS email_domain,
        length(c.c_first_name) AS first_name_len,
        length(c.c_last_name) AS last_name_len,
        concat_ws(' ', lower(c.c_first_name), lower(c.c_last_name)) AS normalized_name
    FROM customer c
    WHERE c.c_email_address IS NOT NULL
),
clean_item AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_item_desc,
        lower(regexp_replace(i.i_item_desc, '[^a-z0-9 ]', '')) AS clean_desc,
        lower(regexp_replace(i.i_product_name, '[^a-z0-9 ]', '')) AS clean_name,
        split(lower(regexp_replace(i.i_product_name, '[^a-z0-9 ]', '')), ' ') AS name_words,
        split(lower(regexp_replace(i.i_item_desc, '[^a-z0-9 ]', '')), ' ') AS desc_words,
        cardinality(split(i.i_product_name, ' ')) AS product_name_word_count,
        length(i.i_product_name) AS product_name_len,
        i.i_category,
        i.i_color,
        i.i_size
    FROM item i
),
flattened_words AS (
    SELECT ci.i_item_sk, token
    FROM clean_item ci
    CROSS JOIN UNNEST(ci.name_words) AS t(token)
    WHERE token <> ''
),
word_counts AS (
    SELECT i_item_sk, token AS word, count(*) AS cnt
    FROM flattened_words
    GROUP BY i_item_sk, token
),
top_words AS (
    SELECT i_item_sk,
           array_join(slice(array_agg(word ORDER BY cnt DESC), 1, 3), ', ') AS top_3_words
    FROM word_counts
    GROUP BY i_item_sk
),
sales_by_source AS (
    SELECT cs.cs_item_sk AS item_sk, sum(cs.cs_net_paid) AS net_paid, sum(cs.cs_quantity) AS qty, 'catalog' AS src
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk
    UNION ALL
    SELECT ss.ss_item_sk AS item_sk, sum(ss.ss_net_paid) AS net_paid, sum(ss.ss_quantity) AS qty, 'store' AS src
    FROM store_sales ss
    GROUP BY ss.ss_item_sk
    UNION ALL
    SELECT ws.ws_item_sk AS item_sk, sum(ws.ws_net_paid) AS net_paid, sum(ws.ws_quantity) AS qty, 'web' AS src
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
agg_sales AS (
    SELECT
        item_sk,
        sum(CASE WHEN src = 'catalog' THEN net_paid END) AS total_sales_cs,
        sum(CASE WHEN src = 'store' THEN net_paid END) AS total_sales_ss,
        sum(CASE WHEN src = 'web' THEN net_paid END) AS total_sales_ws,
        sum(CASE WHEN src = 'catalog' THEN qty END) AS total_qty_cs,
        sum(CASE WHEN src = 'store' THEN qty END) AS total_qty_ss,
        sum(CASE WHEN src = 'web' THEN qty END) AS total_qty_ws
    FROM sales_by_source
    GROUP BY item_sk
),
customer_spend AS (
    SELECT cs.cs_item_sk AS item_sk, ed.email_domain, sum(cs.cs_net_paid) AS domain_spent
    FROM catalog_sales cs
    JOIN email_domains ed ON cs.cs_bill_customer_sk = ed.c_customer_sk
    GROUP BY cs.cs_item_sk, ed.email_domain
    UNION ALL
    SELECT ss.ss_item_sk AS item_sk, ed.email_domain, sum(ss.ss_net_paid) AS domain_spent
    FROM store_sales ss
    JOIN email_domains ed ON ss.ss_customer_sk = ed.c_customer_sk
    GROUP BY ss.ss_item_sk, ed.email_domain
    UNION ALL
    SELECT ws.ws_item_sk AS item_sk, ed.email_domain, sum(ws.ws_net_paid) AS domain_spent
    FROM web_sales ws
    JOIN email_domains ed ON ws.ws_bill_customer_sk = ed.c_customer_sk
    GROUP BY ws.ws_item_sk, ed.email_domain
),
domain_stats AS (
    SELECT item_sk,
           avg(domain_spent) AS avg_domain_spent,
           array_join(array_agg(distinct email_domain), ', ') AS domains_involved
    FROM customer_spend
    GROUP BY item_sk
)
SELECT
    ci.i_item_sk,
    ci.i_product_name,
    ci.i_item_desc,
    ci.clean_desc,
    ci.product_name_len,
    ci.product_name_word_count,
    ci.i_category,
    ci.i_color,
    ci.i_size,
    concat_ws(' - ', ci.i_product_name, ci.i_category) AS prod_cat_concat,
    regexp_extract_all(ci.i_product_name, '\\d+') AS numeric_tokens,
    tw.top_3_words,
    agg.total_sales_cs,
    agg.total_sales_ss,
    agg.total_sales_ws,
    (coalesce(agg.total_qty_cs, 0) + coalesce(agg.total_qty_ss, 0) + coalesce(agg.total_qty_ws, 0)) AS total_quantity_sold,
    ds.avg_domain_spent,
    ds.domains_involved,
    CASE WHEN position('-' IN ci.i_product_name) > 0 THEN 'HAS_HYPHEN' ELSE 'NO_HYPHEN' END AS hyphen_flag,
    substr(ci.clean_desc, 1, 10) AS clean_desc_prefix,
    replace(ci.clean_desc, 'promo', 'PROMO') AS desc_promo_upper,
    trim(both ' ' FROM ci.i_product_name) AS trimmed_product_name,
    length(trim(both ' ' FROM ci.i_product_name)) AS trimmed_name_len
FROM clean_item ci
LEFT JOIN top_words tw ON ci.i_item_sk = tw.i_item_sk
LEFT JOIN agg_sales agg ON ci.i_item_sk = agg.item_sk
LEFT JOIN domain_stats ds ON ci.i_item_sk = ds.item_sk
WHERE ci.i_product_name IS NOT NULL
ORDER BY agg.total_sales_cs DESC NULLS LAST
LIMIT 50
