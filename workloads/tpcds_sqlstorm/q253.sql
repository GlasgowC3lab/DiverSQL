SELECT
    lower(regexp_replace(i.i_item_id, '-', '')) AS clean_item_id,
    lower(trim(p.p_promo_name)) AS clean_promo_name,
    upper(concat(c.c_first_name, ' ', c.c_last_name)) AS customer_name_up,
    lower(d.d_day_name) AS day_name_lc,
    substring(i.i_item_desc, 1, 10) AS item_desc_prefix,
    length(i.i_item_desc) AS item_desc_len,
    cardinality(regexp_extract_all(lower(i.i_item_desc), '\\bthe\\b')) AS the_word_cnt,
    length(i.i_item_desc) - length(replace(i.i_item_desc, ',', '')) AS comma_cnt,
    regexp_extract(i.i_item_desc, '^([^\\s]+)', 1) AS first_word_desc,
    replace(i.i_item_desc, '\\n', ' ') AS desc_no_newline,
    reverse(i.i_item_id) AS rev_item_id,
    trim(i.i_product_name) AS trimmed_product_name,
    lower(c.c_email_address) AS email_lc,
    split_part(c.c_email_address, '@', 1) AS email_local_part,
    split_part(c.c_email_address, '@', 2) AS email_domain_part,
    concat_ws(' ', s.s_store_name, s.s_city, s.s_state) AS store_location,
    upper(s.s_store_name) AS store_name_up,
    replace(s.s_store_name, ',', '') AS store_name_no_comma,
    CASE WHEN regexp_like(i.i_item_desc, '.*(NEW|REFURB).*') THEN 'YES' ELSE 'NO' END AS is_new_or_refurb,
    COALESCE(i.i_color, 'UNKNOWN') AS item_color,
    sum(ss.ss_net_paid) AS total_net_paid,
    sum(ss.ss_net_profit) AS total_net_profit,
    count(*) AS sales_cnt,
    avg(ss.ss_quantity) AS avg_quantity,
    count(distinct p.p_promo_sk) AS distinct_promos,
    min(date_add('day', ss.ss_sold_date_sk, DATE '1970-01-01')) AS min_sold_date,
    max(date_add('day', ss.ss_sold_date_sk, DATE '1970-01-01')) AS max_sold_date
FROM
    store_sales ss
JOIN
    item i ON ss.ss_item_sk = i.i_item_sk
JOIN
    store s ON ss.ss_store_sk = s.s_store_sk
JOIN
    customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN
    promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE
    i.i_item_desc IS NOT NULL
GROUP BY
    i.i_item_id,
    p.p_promo_name,
    c.c_first_name,
    c.c_last_name,
    d.d_day_name,
    i.i_item_desc,
    i.i_product_name,
    c.c_email_address,
    s.s_store_name,
    s.s_city,
    s.s_state,
    i.i_color
