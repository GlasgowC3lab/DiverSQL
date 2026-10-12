WITH
customer_clean AS (
    SELECT
        c_customer_sk,
        concat_ws(' ', trim(c_first_name), trim(c_last_name)) AS full_name,
        lower(trim(c_email_address)) AS email_clean,
        element_at(split(lower(trim(c_email_address)), '@'), 2) AS email_domain
    FROM
        customer
),
item_clean AS (
    SELECT
        i_item_sk,
        regexp_replace(trim(i_item_desc), '\\s+', ' ') AS cleaned_desc,
        length(regexp_replace(trim(i_item_desc), '\\s+', ' ')) AS desc_len
    FROM
        item
),
store_addr AS (
    SELECT
        s_store_sk,
        concat_ws(' ',
            coalesce(s_street_number, ''),
            coalesce(s_street_name, ''),
            coalesce(s_street_type, ''),
            CASE WHEN s_suite_number IS NOT NULL THEN concat('Suite ', s_suite_number) ELSE '' END,
            s_city,
            s_state,
            s_zip
        ) AS full_address,
        length(concat_ws(' ',
            coalesce(s_street_number, ''),
            coalesce(s_street_name, ''),
            coalesce(s_street_type, ''),
            CASE WHEN s_suite_number IS NOT NULL THEN concat('Suite ', s_suite_number) ELSE '' END,
            s_city,
            s_state,
            s_zip
        )) AS address_len,
        concat_ws(' - ', s_store_name, s_city, s_state) AS store_label
    FROM
        store
),
promo_info AS (
    SELECT
        p_promo_sk,
        lower(p_promo_name) AS promo_name_lc,
        lower(p_channel_details) AS channel_details_lc,
        concat_ws(' | ', lower(p_promo_name), lower(p_channel_details)) AS promo_label,
        CASE
            WHEN regexp_like(lower(p_promo_name), 'discount') THEN 'DISCOUNT'
            WHEN regexp_like(lower(p_promo_name), 'clearance') THEN 'CLEARANCE'
            ELSE 'OTHER'
        END AS promo_category
    FROM
        promotion
),
sales_agg AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        d.d_year,
        d.d_month_seq,
        sum(ss.ss_net_paid) AS total_net_paid,
        avg(ss.ss_quantity) AS avg_quantity,
        count(DISTINCT ss.ss_item_sk) AS distinct_items,
        count(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        array_agg(DISTINCT pi.promo_label) AS promo_labels,
        array_agg(DISTINCT cc.email_domain) AS email_domains,
        avg(ic.desc_len) AS avg_item_desc_len,
        sum(CASE WHEN regexp_like(ic.cleaned_desc, '(?i)organic') THEN 1 ELSE 0 END) AS organic_item_cnt
    FROM
        store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item_clean ic ON ss.ss_item_sk = ic.i_item_sk
        JOIN customer_clean cc ON ss.ss_customer_sk = cc.c_customer_sk
        LEFT JOIN promo_info pi ON ss.ss_promo_sk = pi.p_promo_sk
    WHERE
        d.d_year BETWEEN 1999 AND 2001
        AND (regexp_like(ic.cleaned_desc, '(?i)fresh') OR regexp_like(ic.cleaned_desc, '(?i)organic'))
    GROUP BY
        ss.ss_store_sk,
        d.d_year,
        d.d_month_seq
)
SELECT
    a.store_label,
    a.full_address,
    a.address_len,
    sa.d_year,
    sa.d_month_seq,
    concat(cast(sa.d_year AS varchar), '-', lpad(cast(((sa.d_month_seq - 1) % 12) + 1 AS varchar), 2, '0')) AS year_month,
    format('%.2f', sa.total_net_paid) AS total_net_paid_formatted,
    round(sa.avg_quantity, 2) AS avg_quantity,
    sa.distinct_items,
    sa.distinct_customers,
    cardinality(sa.email_domains) AS distinct_email_domains,
    cardinality(sa.promo_labels) AS distinct_promo_labels,
    round(sa.avg_item_desc_len, 2) AS avg_item_desc_len,
    sa.organic_item_cnt
FROM
    sales_agg sa
    JOIN store_addr a ON sa.store_sk = a.s_store_sk
ORDER BY
    sa.total_net_paid DESC
LIMIT 100
