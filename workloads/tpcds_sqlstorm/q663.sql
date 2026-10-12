WITH agg AS (
    SELECT
        i.i_brand,
        i.i_size,
        i.i_color,
        i.i_item_desc,
        i.i_product_name,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        sum(ss.ss_net_paid) AS total_net_paid,
        sum(ss.ss_ext_sales_price) AS total_ext_sales,
        count(*) AS sales_transactions,
        min(d.d_year) AS first_sale_year,
        max(d.d_year) AS last_sale_year
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE i.i_item_desc IS NOT NULL
      AND i.i_color IS NOT NULL
      AND d.d_year BETWEEN 1999 AND 2002
      AND regexp_like(i.i_item_desc, '(?i)\\b(large|medium|small)\\b')
    GROUP BY
        i.i_brand,
        i.i_size,
        i.i_color,
        i.i_item_desc,
        i.i_product_name,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address
)
SELECT
    concat_ws('_', lower(trim(i_brand)), trim(i_size), lower(trim(i_color))) AS brand_key,
    regexp_extract(i_item_desc, '(?i)(brown|black|blue|red|green|yellow|white|orange|purple|gray)', 1) AS extracted_color,
    length(i_product_name) AS product_name_len,
    cardinality(split(i_product_name, '\\s+')) AS product_name_word_count,
    reverse(i_product_name) AS product_name_rev,
    total_net_paid,
    total_ext_sales,
    sales_transactions,
    first_sale_year,
    last_sale_year,
    concat('Brand ', i_brand, ' size ', i_size, ' color ', i_color) AS descriptive_label,
    trim(concat(' ', i_brand, ' ', i_size, ' ', i_color, ' ')) AS trimmed_concat,
    replace(replace(i_item_desc, '-', ' '), ',', '') AS cleaned_desc,
    regexp_replace(i_item_desc, '\\s+', ' ') AS normalized_desc,
    concat_ws('-', cast(ss_sold_date_sk AS varchar), cast(ss_sold_time_sk AS varchar)) AS sold_timestamp_key,
    concat_ws('|', c_first_name, c_last_name) AS customer_name_concat,
    concat_ws('', c_email_address, '-1') AS email_dummy,
    CASE
        WHEN regexp_like(c_email_address, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$') THEN 'valid_email'
        ELSE 'invalid_email'
    END AS email_validity,
    row_number() OVER (PARTITION BY i_brand ORDER BY total_net_paid DESC) AS brand_rank_by_sales
FROM agg
ORDER BY total_net_paid DESC
LIMIT 10
