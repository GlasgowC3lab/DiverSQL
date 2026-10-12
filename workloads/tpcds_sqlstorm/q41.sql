WITH sales_data AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d.d_year,
        ss.ss_net_paid,
        ss.ss_net_profit,
        i.i_item_sk,
        i.i_product_name,
        replace(lower(i.i_product_name), '-', ' ') AS product_name_clean,
        substring(i.i_item_desc, 1, 10) AS short_desc,
        regexp_replace(i.i_item_desc, '[^A-Za-z0-9 ]', '') AS item_desc_alnum,
        c.c_email_address,
        regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
        p.p_discount_active,
        p.p_promo_name,
        i.i_category,
        i.i_brand
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND s.s_state = 'CA'
)
SELECT
    sd.s_store_id,
    sd.d_year,
    lower(trim(sd.s_store_name)) AS normalized_store_name,
    sum(sd.ss_net_paid) AS total_net_paid,
    avg(sd.ss_net_profit) AS avg_net_profit,
    array_join(
        array_sort(
            array_distinct(
                array_agg(upper(substr(sd.product_name_clean, 1, 1)))
            )
        ), ','
    ) AS distinct_product_initials,
    array_join(
        array_sort(
            array_distinct(
                array_agg(sd.email_domain)
            )
        ), ','
    ) AS unique_email_domains,
    max(sd.item_desc_alnum) AS max_clean_desc,
    sum(
        length(sd.item_desc_alnum) -
        length(regexp_replace(sd.item_desc_alnum, '[AEIOUaeiou]', ''))
    ) AS consonant_count,
    count(distinct sd.p_promo_name) AS promo_name_count,
    concat_ws('|',
        array_join(array_distinct(array_agg(lower(trim(sd.i_category)))), ',')
    ) AS categories_concat,
    concat_ws('|',
        array_join(array_distinct(array_agg(lower(trim(sd.i_brand)))), ',')
    ) AS brands_concat
FROM sales_data sd
GROUP BY
    sd.s_store_id,
    sd.d_year,
    sd.s_store_name
